import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        header: true,
        label: AppLocalizations.of(context)!.history,
        excludeSemantics: false,
        child: Text(
          AppLocalizations.of(context)!.history,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
