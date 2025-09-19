import 'dart:async';
import 'package:flutter/services.dart';

class ConnectivityChannel {
  static const MethodChannel _channel = MethodChannel('nabd/connectivity');
  static final StreamController<Map<String, dynamic>> _eventController = 
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  static void _setupEventChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'qr_visible':
          _eventController.add({'type': 'qr_visible'});
          break;
        case 'qr_parsed':
          _eventController.add({
            'type': 'qr_parsed',
            'ssid': call.arguments['ssid'],
            'password': call.arguments['password']
          });
          break;
        case 'capture_blocked':
          _eventController.add({'type': 'capture_blocked'});
          break;
        case 'failure':
          _eventController.add({
            'type': 'failure',
            'reason': call.arguments['reason']
          });
          break;
      }
    });
  }

  static Future<void> initialize() async {
    _setupEventChannel();
  }

  static Future<bool> requestScreenCapture() async {
    try {
      final result = await _channel.invokeMethod('request_screen_capture');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('open_wifi_settings');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> captureOnce() async {
    try {
      await _channel.invokeMethod('capture_once');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> setFlagSecure(bool enable) async {
    try {
      await _channel.invokeMethod('set_flag_secure', {'enable': enable});
    } catch (e) {
      // Handle error silently
    }
  }

  static void dispose() {
    _eventController.close();
  }
}