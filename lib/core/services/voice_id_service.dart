import 'package:flutter/services.dart';

const _platform = MethodChannel('nabd/voiceid');

class VoiceIdService {
  Future<List<int>?> enrollVoice(String accessKey) async {
    try {
      final List<dynamic>? fileBytes = await _platform.invokeMethod(
        'enrollVoice',
        {
          'accessKey': accessKey,
        },
      );
      if (fileBytes != null) {
        return fileBytes.cast<int>();
      }
      return null;
    } on PlatformException catch (e) {
      print("Failed to enroll voice: '${e.message}'.");
      return null;
    }
  }

  Future<void> resetEnrollment() async {
    try {
      await _platform.invokeMethod('resetEnrollment');
    } on PlatformException catch (e) {
      print("Failed to reset enrollment: '${e.message}'.");
    }
  }

  Future<bool> isProfileEnrolled() async {
    try {
      final bool? isEnrolled = await _platform.invokeMethod('isProfileEnrolled');
      return isEnrolled ?? false;
    } on PlatformException catch (e) {
      print("Failed to check profile enrollment: '${e.message}'.");
      return false;
    }
  }
}
