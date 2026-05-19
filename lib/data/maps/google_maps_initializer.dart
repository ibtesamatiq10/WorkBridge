import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_ios/google_maps_flutter_ios.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

Completer<void>? _readyCompleter;

Future<void> ensureGoogleMapsReady() async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return;
  }

  if (_readyCompleter != null) {
    return _readyCompleter!.future;
  }

  final completer = Completer<void>();
  _readyCompleter = completer;

  try {
    WidgetsFlutterBinding.ensureInitialized();

    if (Platform.isAndroid) {
      GoogleMapsFlutterAndroid.registerWith();
      final android =
          GoogleMapsFlutterPlatform.instance as GoogleMapsFlutterAndroid;
      try {
        await android.initializeWithRenderer(AndroidMapRenderer.platformDefault);
      } catch (e) {
        debugPrint('Google Maps renderer already initialized or failed: $e');
      }
      await android.warmup();
    } else if (Platform.isIOS) {
      GoogleMapsFlutterIOS.registerWith();
    }

    completer.complete();
  } catch (e, stack) {
    debugPrint('Google Maps initialization failed: $e\n$stack');
    completer.complete();
  }

  return completer.future;
}

void preloadGoogleMaps() {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return;
  }
  unawaited(ensureGoogleMapsReady());
}
