import 'package:shake/shake.dart';

class ShakeDetectorService {
  ShakeDetector? _detector;

  void start({required void Function(ShakeEvent event) onShake}) {
    if (_detector != null) {
      print("Shake detector is already active.");
      return;
    }

    _detector = ShakeDetector.autoStart(
      onPhoneShake: onShake,
      shakeThresholdGravity: 1.5,
    );
    print("Shake detector started successfully.");
  }

  void stop() {
    if (_detector != null) {
      print("Stopping shake detector.");
      _detector!.stopListening();
      _detector = null;
    }
  }
}
