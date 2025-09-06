import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class PdfReaderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        header: true,
        label: AppLocalizations.of(context)!.pdfreader,
        excludeSemantics: false,
        child: Text(
          AppLocalizations.of(context)!.pdfreader,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
