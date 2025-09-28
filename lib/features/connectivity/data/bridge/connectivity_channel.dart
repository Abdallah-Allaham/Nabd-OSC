import 'dart:async';
import 'package:flutter/services.dart';

class ConnectivityChannel {
  static const MethodChannel _channel = MethodChannel('nabd/connectivity');
  static final StreamController<Map<String, dynamic>> _eventController = 
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  static Function(String, dynamic)? _methodCallHandler;

  static void _setupEventChannel() {
    _channel.setMethodCallHandler((call) async {
      // Handle internal events
      switch (call.method) {
        case 'settings_list_visible':
          _eventController.add({'type': 'settings_list_visible'});
          break;
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
      
      // Call custom handler if set
      if (_methodCallHandler != null) {
        _methodCallHandler!(call.method, call.arguments);
      }
    });
  }

  static void setMethodCallHandler(Function(String, dynamic) handler) {
    _methodCallHandler = handler;
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

  static Future<void> invoke(String method, [dynamic arguments]) async {
    try {
      await _channel.invokeMethod(method, arguments);
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<bool> isScreenCaptureReady() async {
    try {
      final result = await _channel.invokeMethod('is_screen_capture_ready');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> resetConnectivitySessionFlags() async {
    try {
      await _channel.invokeMethod('reset_connectivity_session_flags');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> connectivityFlowStart() async {
    try {
      await _channel.invokeMethod('connectivity_flow_start');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> connectivityFlowEnd() async {
    try {
      await _channel.invokeMethod('connectivity_flow_end');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<String> getWifiPassword(String ssid) async {
    try {
      final result = await _channel.invokeMethod('get_wifi_password', {'ssid': ssid});
      return result as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  // Prewarm methods
  static Future<void> prewarmStart() async {
    try {
      await _channel.invokeMethod('prewarm_start');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> prewarmStop() async {
    try {
      await _channel.invokeMethod('prewarm_stop');
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<bool> captureFromPrewarm() async {
    try {
      final result = await _channel.invokeMethod('capture_from_prewarm');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    _eventController.close();
  }
}