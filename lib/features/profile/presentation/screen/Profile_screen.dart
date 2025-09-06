import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'محمد';
  String phoneNumber = '+962788048682';

  Future<void> _editField(
      String fieldKey, String currentValue, Function(String) onSave) async {
    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        String fieldLabel = _getLabel(localizations, fieldKey);
        return AlertDialog(
          backgroundColor:
          Theme.of(context).colorScheme.surface.withOpacity(0.9),
          title: Text(
            '${localizations.edit} $fieldLabel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            controller: controller,
            textDirection: Directionality.of(context),
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: localizations.new_value(fieldLabel),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(localizations.save),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      setState(() => onSave(result.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Semantics(
                    header: true,
                    label: localizations.account_info,
                    child: Text(
                      localizations.account_info,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 120),
              _buildInfoField(
                label: localizations.name,
                value: userName,
                onEdit: () =>
                    _editField('name', userName, (val) => userName = val),
              ),
              const SizedBox(height: 30),
              _buildInfoField(
                label: localizations.phone,
                value: phoneNumber,
                onEdit: () => _editField(
                    'phone', phoneNumber, (val) => phoneNumber = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: '$label: $value',
                excludeSemantics: false,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(fontSize: 17, color: Colors.white),
              ),
              const Divider(color: Colors.white),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: onEdit,
        ),
      ],
    );
  }

  String _getLabel(AppLocalizations localizations, String fieldKey) {
    switch (fieldKey) {
      case 'name':
        return localizations.name;
      case 'phone':
        return localizations.phone;
      default:
        return fieldKey;
    }
  }
}
