import 'package:flutter/widgets.dart';
import 'package:flutter_speech/flutter_speech.dart';

class STTService {
  final SpeechRecognition _speech = SpeechRecognition();
  bool _isListening = false;
  String _recognizedText = '';
  void Function(String)? _onResultCallback;
  void Function(String)? _onCompletionCallback;

  // Constructor
  STTService() {
    _speech.setAvailabilityHandler((bool result) {
      print("STT Service is available: $result");
    });

    _speech.setRecognitionStartedHandler(() {
      _isListening = true;
      _recognizedText = '';
      print("STT listening started.");
    });

    _speech.setRecognitionResultHandler((String text) {
      if (!_isListening) {
        return;
      }
      _recognizedText = text;
      _onResultCallback?.call(text);
      print("STT recognized text: $text");
    });

    _speech.setRecognitionCompleteHandler((String text) {
      _isListening = false;
      _recognizedText = text;
      _onCompletionCallback?.call(text);
      print("STT listening complete, final text: $text");
    });
  }

  String get recognizedText => _recognizedText;

  bool get isListening => _isListening;

  Future<void> initialize({
    // تم إزالة `required String locale`
    required void Function(String) onResult,
    required void Function(String) onCompletion,
  }) async {
    _onResultCallback = onResult;
    _onCompletionCallback = onCompletion;

    // تحديد لغة الجهاز تلقائياً
    final String systemLangCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final String locale = systemLangCode == 'ar' ? 'ar_SA' : 'en_US';

    await _speech.activate(locale);
  }

  Future<void> startListening() async {
    if (!_isListening) {
      _recognizedText = '';
      final bool available = await _speech.listen();
      if (!available) {
        print("Failed to start listening. Check permissions or locale.");
        _isListening = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
}