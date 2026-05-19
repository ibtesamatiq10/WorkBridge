import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:WorkBridge/data/agent/antigravity_platform_service.dart';
import 'package:WorkBridge/data/repositories/provider_repository_impl.dart';
import 'package:WorkBridge/domain/entities/booking.dart';
import 'package:WorkBridge/domain/entities/provider.dart' as domain;
import 'package:WorkBridge/domain/entities/service_request.dart';
import 'package:WorkBridge/domain/entities/workflow_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:WorkBridge/data/notifications/notification_service.dart';

final antigravityPlatformProvider = Provider<AntigravityPlatformService?>(
  (ref) => null,
);

final providerRepositoryProvider = Provider<ProviderRepository>(
  (ref) => ProviderRepository(''),
);

class NotificationPayload {
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final String? bookedBy;
  final domain.Provider? provider;
  final ServiceRequest? request;

  const NotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.bookedBy,
    this.provider,
    this.request,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'bookedBy': bookedBy,
      if (provider != null) 'provider': _providerToJson(provider!),
      if (request != null) 'request': _requestToJson(request!),
    };
  }

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      bookedBy: json['bookedBy'] as String?,
      provider: json['provider'] != null
          ? _providerFromJson(json['provider'] as Map<String, dynamic>)
          : null,
      request: json['request'] != null
          ? _requestFromJson(json['request'] as Map<String, dynamic>)
          : null,
    );
  }

  static Map<String, dynamic> _providerToJson(domain.Provider p) {
    return {
      'id': p.id,
      'name': p.name,
      'serviceType': p.serviceType,
      'rating': p.rating,
      'distanceKm': p.distanceKm,
      'isAvailable': p.isAvailable,
      'address': p.address,
      'totalRatings': p.totalRatings,
      'latitude': p.latitude,
      'longitude': p.longitude,
    };
  }

  static domain.Provider _providerFromJson(Map<String, dynamic> map) {
    return domain.Provider(
      id: map['id'] as String,
      name: map['name'] as String,
      serviceType: map['serviceType'] as String,
      rating: (map['rating'] as num).toDouble(),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      isAvailable: map['isAvailable'] as bool,
      address: map['address'] as String?,
      totalRatings: map['totalRatings'] as int?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> _requestToJson(ServiceRequest r) {
    return {
      'serviceType': r.serviceType,
      'location': r.location,
      'time': r.time,
    };
  }

  static ServiceRequest _requestFromJson(Map<String, dynamic> map) {
    return ServiceRequest(
      serviceType: map['serviceType'] as String,
      location: map['location'] as String,
      time: map['time'] as String,
    );
  }
}

class WorkflowState {
  final bool isProcessing;
  final List<WorkflowLog> logs;
  final ServiceRequest? currentRequest;
  final List<domain.Provider> matchedProviders;
  final domain.Provider? recommendedProvider;
  final domain.Provider? viewedProvider;
  final String? reasoning;
  final Booking? booking;
  final NotificationPayload? activeNotification;
  final List<NotificationPayload> notifications;
  final Map<String, DateTime> bookedProviders;

  WorkflowState({
    this.isProcessing = false,
    this.logs = const [],
    this.currentRequest,
    this.matchedProviders = const [],
    this.recommendedProvider,
    this.viewedProvider,
    this.reasoning,
    this.booking,
    this.activeNotification,
    this.notifications = const [],
    this.bookedProviders = const {},
  });

  bool isProviderBusy(String providerId) {
    final bookingTime = bookedProviders[providerId];
    if (bookingTime == null) return false;
    final difference = DateTime.now().difference(bookingTime);
    return difference.inSeconds < 60;
  }

  int busySecondsRemaining(String providerId) {
    final bookingTime = bookedProviders[providerId];
    if (bookingTime == null) return 0;
    final difference = DateTime.now().difference(bookingTime);
    final remaining = 60 - difference.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  WorkflowState copyWith({
    bool? isProcessing,
    List<WorkflowLog>? logs,
    ServiceRequest? currentRequest,
    List<domain.Provider>? matchedProviders,
    domain.Provider? recommendedProvider,
    domain.Provider? viewedProvider,
    bool clearViewedProvider = false,
    String? reasoning,
    Booking? booking,
    bool clearBooking = false,
    NotificationPayload? activeNotification,
    bool clearNotification = false,
    List<NotificationPayload>? notifications,
    Map<String, DateTime>? bookedProviders,
  }) {
    return WorkflowState(
      isProcessing: isProcessing ?? this.isProcessing,
      logs: logs ?? this.logs,
      currentRequest: currentRequest ?? this.currentRequest,
      matchedProviders: matchedProviders ?? this.matchedProviders,
      recommendedProvider: recommendedProvider ?? this.recommendedProvider,
      viewedProvider: clearViewedProvider
          ? null
          : (viewedProvider ?? this.viewedProvider),
      reasoning: reasoning ?? this.reasoning,
      booking: clearBooking ? null : (booking ?? this.booking),
      activeNotification: clearNotification
          ? null
          : (activeNotification ?? this.activeNotification),
      notifications: notifications ?? this.notifications,
      bookedProviders: bookedProviders ?? this.bookedProviders,
    );
  }
}

class WorkflowOrchestrator extends Notifier<WorkflowState> {
  @override
  WorkflowState build() {
    return WorkflowState();
  }

  void _addLog(String step, String message) {
    state = state.copyWith(
      logs: [
        ...state.logs,
        WorkflowLog(timestamp: DateTime.now(), step: step, message: message),
      ],
    );
  }

  Future<void> processUserRequest(String input) async {
    final _agentService = ref.read(antigravityPlatformProvider);
    final _providerRepository = ref.read(providerRepositoryProvider);

    if (_agentService == null) {
      throw Exception(
        'Gemini API Key is missing. Antigravity service not initialized.',
      );
    }

    state = WorkflowState(isProcessing: true, logs: []);
    _addLog('Input Received', 'User said: "$input"');

    _addLog(
      'Antigravity | Natural Language Processing',
      'Extracting intent using Google Antigravity core platform...',
    );
    final intentResult = await _agentService.extractIntent(input);
    final request = intentResult.request;

    if (intentResult.notice != null) {
      _addLog('Antigravity | Notice', intentResult.notice!);
    }
    if (intentResult.usedLocalFallback) {
      _addLog(
        'Antigravity | Local NLP',
        'Parsed intent offline (no Gemini call).',
      );
    }

    state = state.copyWith(currentRequest: request);
    _addLog(
      'Antigravity | Intent Extracted',
      'Service: ${request.serviceType}, Location: ${request.location}, Time: ${request.time}',
    );

    _addLog(
      'Antigravity | Tool Integration',
      'Connecting to Google Maps API to establish coordinates for ${request.location}...',
    );
    await Future.delayed(const Duration(milliseconds: 600));
    _addLog(
      'Antigravity | Tool Integration',
      'Using Search API to find providers within a 10km radius...',
    );
    await Future.delayed(const Duration(milliseconds: 600));

    final searchResult = await _providerRepository.findNearbyProviders(
      request.serviceType,
      request.location,
    );
    final providers = searchResult.providers;
    state = state.copyWith(matchedProviders: providers);
    _addLog(
      'Antigravity | Discovery Result',
      'Found ${providers.length} matching ${request.serviceType} options nearby.',
    );

    if (providers.isEmpty) {
      final detail =
          searchResult.diagnosticMessage ?? 'No results from Places API.';
      _addLog('Antigravity | Maps API', detail);
      _addLog(
        'Antigravity | Decision',
        'Workflow terminated due to zero availability.',
      );
      state = state.copyWith(isProcessing: false);
      return;
    }

    final availableProviders = providers
        .where((p) => !state.isProviderBusy(p.id))
        .toList();

    if (availableProviders.isEmpty) {
      _addLog(
        'Antigravity | Agent Decision',
        'All found providers are currently busy on other active bookings! Please wait a few seconds and try again.',
      );
      state = state.copyWith(isProcessing: false);
      return;
    }

    _addLog(
      'Antigravity | Multi-step Reasoning',
      'Evaluating ${availableProviders.length} available options based on proximity, ratings, and schedule matching...',
    );
    final decision = await _agentService.selectBestProvider(
      request,
      availableProviders,
    );

    final selectedId = decision['selectedProviderId']?.toString();
    final reason = decision['reason']?.toString();

    if (selectedId == null) {
      _addLog(
        'Antigravity | Agent Decision',
        'Could not select a provider. Reason: $reason',
      );
      state = state.copyWith(isProcessing: false);
      return;
    }

    final recommended = providers.firstWhere(
      (p) => p.id == selectedId,
      orElse: () => availableProviders.first,
    );

    state = state.copyWith(
      recommendedProvider: recommended,
      reasoning: reason,
      isProcessing: false,
      clearViewedProvider: true,
      clearBooking: true,
    );

    _addLog(
      'Antigravity | Agent Decision',
      'Top pick: ${recommended.name}. Tap a provider for details.',
    );
    _addLog(
      'Antigravity | Ready',
      'Select a provider from the list to view details and book.',
    );
  }

  void showProviderDetail(domain.Provider provider) {
    state = state.copyWith(viewedProvider: provider);
    _addLog('User Action', 'Viewing details for ${provider.name}.');
  }

  void showBookedProviderDetail(
    domain.Provider provider,
    ServiceRequest request,
  ) {
    state = state.copyWith(
      viewedProvider: provider,
      currentRequest: request,
      clearBooking: true,
    );
    _addLog(
      'User Action',
      'Viewing details for booked provider: ${provider.name}.',
    );
  }

  void backToProviderList() {
    state = state.copyWith(clearViewedProvider: true);
  }

  void dismissBooking() {
    state = state.copyWith(clearViewedProvider: true, clearBooking: true);
  }

  void triggerNotification(NotificationPayload notification) {
    final newList = [...state.notifications, notification];
    state = state.copyWith(
      activeNotification: notification,
      notifications: newList,
    );

    final currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _saveHistoryToPrefs(currentUser.uid, newList, state.bookedProviders);
    }

    LocalNotificationService.showNotification(
      id: notification.type == 'whatsapp' ? 100 : 101,
      title: notification.title,
      body: notification.body,
    );

    Future.delayed(const Duration(seconds: 6), () {
      if (state.activeNotification == notification) {
        state = state.copyWith(clearNotification: true);
      }
    });
  }

  void dismissNotification() {
    state = state.copyWith(clearNotification: true);
  }

  Future<void> _saveHistoryToPrefs(
    String userId,
    List<NotificationPayload> list,
    Map<String, DateTime> bookedMap,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((n) => n.toJson()).toList();
      await prefs.setString('booking_history_$userId', jsonEncode(jsonList));

      final jsonBooked = bookedMap.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      );
      await prefs.setString('booked_providers_$userId', jsonEncode(jsonBooked));
    } catch (e) {
      print('Failed to save booking history: $e');
    }
  }

  Future<void> loadHistoryForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonStr = prefs.getString('booking_history_$userId');
      List<NotificationPayload> loadedNotifications = [];
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        loadedNotifications = decoded
            .map(
              (item) =>
                  NotificationPayload.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      final bookedStr = prefs.getString('booked_providers_$userId');
      Map<String, DateTime> loadedBooked = {};
      if (bookedStr != null) {
        final decoded = jsonDecode(bookedStr) as Map<String, dynamic>;
        loadedBooked = decoded.map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        );
      }

      state = state.copyWith(
        notifications: loadedNotifications,
        bookedProviders: loadedBooked,
      );
    } catch (e) {
      print('Failed to load booking history: $e');
    }
  }

  Future<void> bookProvider(domain.Provider provider) async {
    final request = state.currentRequest;
    if (request == null) return;

    state = state.copyWith(isProcessing: true, viewedProvider: provider);

    _addLog('Antigravity | Action Execution', 'Booking ${provider.name}...');
    await Future.delayed(const Duration(seconds: 1));

    final booking = Booking(
      id: const Uuid().v4().substring(0, 8),
      request: request,
      provider: provider,
      status: 'Confirmed',
      scheduledTime: DateTime.now().add(const Duration(days: 1)),
    );

    final reason =
        state.reasoning ??
        'Booked based on your selection (${provider.distanceKm} km, ★ ${provider.rating.toStringAsFixed(1)}).';

    final newBookings = Map<String, DateTime>.from(state.bookedProviders);
    newBookings[provider.id] = DateTime.now();

    state = state.copyWith(
      booking: booking,
      reasoning: reason,
      isProcessing: false,
      bookedProviders: newBookings,
    );

    _addLog(
      'Antigravity | Booking Confirmed',
      'Slot booked for ${booking.scheduledTime}. Confirmation sent.',
    );

    final currentUser = fb.FirebaseAuth.instance.currentUser;
    final userName = currentUser?.displayName ?? '';
    final userEmail = currentUser?.email ?? '';
    final bookedByString = userName.isNotEmpty
        ? '$userName ($userEmail)'
        : userEmail;

    triggerNotification(
      NotificationPayload(
        title: 'WorkBridge',
        body:
            'Hi! Your booking with ${provider.name} for ${request.serviceType} is confirmed for ${request.time}. Ref ID: ${booking.id}. - Google Antigravity',
        type: 'whatsapp',
        timestamp: DateTime.now(),
        bookedBy: bookedByString.isNotEmpty ? bookedByString : null,
        provider: provider,
        request: request,
      ),
    );
  }
}

final workflowOrchestratorProvider =
    NotifierProvider<WorkflowOrchestrator, WorkflowState>(() {
      return WorkflowOrchestrator();
    });
