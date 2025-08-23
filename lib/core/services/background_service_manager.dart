import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../injection_container.dart';

const _platform = MethodChannel('nabd/foreground');

Future<void> startBackgroundListening() async {
  final String? picoVoiceAccessKey = sl<KeyManager>().picoVoiceAccessKey;
  if (picoVoiceAccessKey == null) {
    print("Error: PICOVOICE_ACCESS_KEY is not defined in the service locator.");
    return;
  }

  try {
    await _platform.invokeMethod('startService', {
      'apiKey': picoVoiceAccessKey,
    });
    print("Background service started successfully.");
  } on PlatformException catch (e) {
    print("Failed to start background service: '${e.message}'.");
  }
}

Future<void> stopBackgroundListening() async {
  try {
    await _platform.invokeMethod('stopService');
    print("Background service stopped successfully.");
  } on PlatformException catch (e) {
    print("Failed to stop background service: '${e.message}'.");
  }
}

class BackgroundServiceManager with WidgetsBindingObserver {
  BackgroundServiceManager() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      startBackgroundListening();
    }
    else if (state == AppLifecycleState.resumed) {
      stopBackgroundListening();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}


class KeyManager {
  final String picoVoiceAccessKey;

  KeyManager({required this.picoVoiceAccessKey});
}

