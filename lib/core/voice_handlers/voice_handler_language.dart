import 'package:flutter/material.dart';

import '../../features/setting/presentation/widget/language_dialog.dart';

class LanguageVoiceHandler {
  static Future<bool> handle(
      BuildContext context,
      Map<String, dynamic> intent, {
        String? originalText,
      }) async {
    if (intent['id'] == 'settings.change_language') {
      LanguageDialog.show(context);
      return true;
    }
    return false;
  }
}
