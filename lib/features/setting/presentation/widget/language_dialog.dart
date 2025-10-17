import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../main.dart';

class LanguageDialog {
  static void show(BuildContext context) {
    final isArabic = Localizations
        .localeOf(context)
        .languageCode == 'ar';
    showDialog(
      context: context,
      builder:
          (_) =>
          AlertDialog(
            title: Text(AppLocalizations.of(context)!.switch_language),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('العربية'),
                  leading: Radio<bool>(
                    value: true,
                    groupValue: isArabic,
                    onChanged: (val) {
                      _setLocale(context, const Locale('ar'));
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    _setLocale(context, const Locale('ar'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('English'),
                  leading: Radio<bool>(
                    value: false,
                    groupValue: isArabic,
                    onChanged: (val) {
                      _setLocale(context, const Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    _setLocale(context, const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  static void _setLocale(BuildContext context, Locale locale) {
    MyApp.of(context)!.setLocale(locale);
  }
}
