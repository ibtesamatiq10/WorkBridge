import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:WorkBridge/domain/entities/provider.dart';
import 'package:WorkBridge/domain/entities/service_request.dart';
import 'local_intent_parser.dart';
import 'package:intl/intl.dart';

class IntentExtractionResult {
  final ServiceRequest request;
  final bool usedLocalFallback;
  final String? notice;

  const IntentExtractionResult({
    required this.request,
    this.usedLocalFallback = false,
    this.notice,
  });
}

class AntigravityPlatformService {
  final GenerativeModel? _model;
  final bool useGeminiForIntent;

  AntigravityPlatformService(
    String apiKey, {
    String model = 'gemini-2.0-flash',
    this.useGeminiForIntent = true,
  }) : _model = apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE'
           ? null
           : GenerativeModel(
               model: model,
               apiKey: apiKey,
               generationConfig: GenerationConfig(
                 responseMimeType: 'application/json',
               ),
               systemInstruction: Content.system(
                 'You are Google Antigravity, the core platform for orchestrating agent workflows. Your task is to manage multi-step reasoning, integrate tools, and execute actions.',
               ),
             );

  Future<IntentExtractionResult> extractIntent(String userInput) async {
    if (_model != null && useGeminiForIntent) {
      try {
        final request = await _extractIntentWithGemini(userInput);
        if (request != null) {
          return IntentExtractionResult(request: request);
        }
      } catch (e) {
        if (_isQuotaOrRateLimitError(e)) {
          debugPrint('Gemini quota exceeded, using local intent parser.');
          return IntentExtractionResult(
            request: LocalIntentParser.parse(userInput),
            usedLocalFallback: true,
            notice:
                'Gemini free-tier quota reached. Using offline intent parsing (Maps search still works).',
          );
        }
        debugPrint('Gemini intent error: $e');
      }
    }

    return IntentExtractionResult(
      request: LocalIntentParser.parse(userInput),
      usedLocalFallback: true,
      notice: useGeminiForIntent
          ? null
          : 'Gemini disabled in .env — using offline intent parsing.',
    );
  }

  Future<ServiceRequest?> _extractIntentWithGemini(String userInput) async {
    final prompt =
        '''
Extract the user intent from the following message.
The message may be in Urdu, Roman Urdu, or English.
Return a JSON object with strictly these keys:
"serviceType": (e.g., "AC Technician", "Plumber", "Restaurant", "Electrician", "Tutor")
"location": (full searchable place: area + city + country from the user's message, e.g. "Gulberg, Lahore, Pakistan", "Dubai Marina, Dubai, UAE", "Times Square, New York, USA". Use the city/country the user mentioned — never assume Islamabad or any default city. If none, return "Unknown")
"time": (e.g., "Tomorrow morning", "Today evening", "ASAP", or a specific scheduled time like "Tomorrow at 10:00 AM" if mentioned. If none, return "ASAP")

For dining requests (restaurant, khana, food), set serviceType to "Restaurant".
For Urdu/Roman Urdu terms:
- "kl", "kal": "Tomorrow"
- "aaj": "Today"
- "subah", "subha", "subh": "morning"
- "shaam", "sham": "evening"
- "raat": "night"
- "bjy", "baje": "o'clock" (e.g., "kl subha 10 bjy" should resolve to "Tomorrow at 10:00 AM")

Always preserve the user's city and country in location.

User Input: "$userInput"
''';

    final response = await _model!.generateContent([Content.text(prompt)]);
    if (response.text == null) return null;

    final data = jsonDecode(response.text!) as Map<String, dynamic>;
    var extractedTime = data['time'] as String? ?? 'ASAP';
    if (extractedTime.toUpperCase() == 'ASAP' || extractedTime.trim().isEmpty) {
      final formattedTime = DateFormat('h:mm a').format(DateTime.now());
      extractedTime = 'ASAP ($formattedTime)';
    }

    return ServiceRequest(
      serviceType: data['serviceType'] as String? ?? 'Unknown',
      location: data['location'] as String? ?? 'Unknown',
      time: extractedTime,
    );
  }

  Future<Map<String, dynamic>> selectBestProvider(
    ServiceRequest request,
    List<Provider> availableProviders,
  ) async {
    if (availableProviders.isEmpty) {
      return {
        'selectedProviderId': null,
        'reason':
            'No providers available for the requested service in your area.',
      };
    }

    return _selectBestProviderLocally(request, availableProviders);
  }

  Map<String, dynamic> _selectBestProviderLocally(
    ServiceRequest request,
    List<Provider> providers,
  ) {
    final scored = providers.map((p) {
      final distanceScore = 1 / (p.distanceKm + 0.3);
      final ratingScore = p.rating / 5.0;
      final score = (ratingScore * 0.55) + (distanceScore * 0.45);
      return (provider: p, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first.provider;

    return {
      'selectedProviderId': best.id,
      'reason':
          'Selected ${best.name} (${best.distanceKm} km, ★ ${best.rating.toStringAsFixed(1)}) — best balance of distance and rating for ${request.serviceType} at ${request.location}.',
    };
  }

  bool _isQuotaOrRateLimitError(Object e) {
    final message = e.toString().toLowerCase();
    return message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('429') ||
        message.contains('rate limit');
  }
}
