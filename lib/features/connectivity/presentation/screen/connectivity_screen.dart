import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ConnectivityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Semantics(
            header: true,
            label: AppLocalizations.of(context)!.connectivity,
            excludeSemantics: false,
            child: Text(
                AppLocalizations.of(context)!.connectivity,
              style: const TextStyle(fontSize: 24),
            )));
  }
}
