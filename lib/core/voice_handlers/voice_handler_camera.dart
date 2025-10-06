import 'package:flutter/material.dart';
import '../../features/guidance/presentation/screen/guidance_screen.dart';




class CameraVoiceHandler {
  static Future<bool> handle(
      BuildContext context,
      Map<String, dynamic> intent, {
        String? originalText,
      }) async {
    print("[🟠] CameraVoiceHandler: intent المستلم: $intent, originalText: $originalText");

    if (intent['id'] == 'home.open_camera' || intent['id'] == 'camera.open') {
      print("[🟠] CameraVoiceHandler: تحقق الشرط، سيتم فتح الكاميرا");
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GuidanceScreen()),
      );
      return true;
    }

    print("[🟠] CameraVoiceHandler: لم يتحقق أي شرط، لن ينفذ شيء");
    return false;
  }
}
