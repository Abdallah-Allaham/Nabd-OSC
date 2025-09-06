import 'package:flutter/material.dart';
import '../../features/profile/presentation/screen/Profile_screen.dart';

class ProfileVoiceHandler {
  static Future<bool> handle(
      BuildContext context,
      Map<String, dynamic> intent, {
        String? originalText,
      }) async {
    print("[🔵] ProfileVoiceHandler: intent المستلم: $intent, originalText: $originalText");

    if (intent['id'] == 'settings.open_account' || intent['id'] == 'profile.open') {
      print("[🔵] ProfileVoiceHandler: تحقق الشرط، سيتم فتح البروفايل");
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage()),
      );
      if (result != null && result is String && result.isNotEmpty) {
        print("[🔵] ProfileVoiceHandler: يوجد نتيجة سترجع للصفحة السابقة: $result");
        Future.microtask(() {
          Navigator.of(context).pop(result);
        });
      }
      return true;
    }

    print("[🔵] ProfileVoiceHandler: لم يتحقق أي شرط، لن ينفذ شيء");
    return false;
  }
}
