import 'package:shake/shake.dart';

class ShakeDetectorService {
  ShakeDetector? _detector;
  
  bool get isActive => _detector != null;

  void start({required void Function(ShakeEvent event) onShake}) {
    // تأكد من إيقاف أي detector سابق قبل البدء
    if (_detector != null) {
      print("Shake detector already active, stopping previous one first.");
      stop();
    }

    _detector = ShakeDetector.autoStart(
      onPhoneShake: onShake,
      shakeThresholdGravity: 1.5,
    );
    print("📱 Shake detector started successfully - App is active");
  }

  void stop() {
    if (_detector != null) {
      print("📱 Stopping shake detector - App is in background");
      _detector!.stopListening();
      _detector = null;
    } else {
      print("📱 Shake detector already stopped");
    }
  }
}
