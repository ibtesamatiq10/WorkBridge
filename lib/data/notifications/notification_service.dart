import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final dynamic plugin = _notificationsPlugin;
    try {
      await plugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'booking_channel_id',
        'Booking Notifications',
        description: 'Notifications for provider bookings and updates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidImplementation?.createNotificationChannel(channel);

      await androidImplementation?.requestNotificationsPermission();
    } catch (e) {
      debugPrint("LocalNotificationService initialize error: $e");
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'booking_channel_id',
          'Booking Notifications',
          channelDescription: 'Notifications for provider bookings and updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
          ticker: 'ticker',
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    final dynamic plugin = _notificationsPlugin;
    try {
      await plugin.show(id, title, body, notificationDetails, payload: payload);
    } catch (e) {
      debugPrint("LocalNotificationService showNotification error: $e");
    }
  }
}
