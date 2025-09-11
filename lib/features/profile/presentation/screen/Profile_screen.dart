import 'package:flutter/material.dart';
import '../../../../core/utils/secure_storage_helper.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String phoneNumber = '';
  final FeedbackService _feedbackService = FeedbackService();
  final SecureStorageHelper _secureStorage = SecureStorageHelper();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get user data from secure storage using your new keys
      final name = await _secureStorage.getPrefString(
        key: AppConstants.nameKey,
        defaultValue: '',
      );
      final phone = await _secureStorage.getPrefString(
        key: AppConstants.phoneKey,
        defaultValue: '',
      );
      
      setState(() {
        userName = name;
        phoneNumber = phone;
      });
    } catch (e) {
      _feedbackService.playFailureTone();
      _feedbackService.vibrateMedium();
    }
  }

  Future<void> _editField(
      String fieldKey, String currentValue, Function(String) onSave) async {
    final controller = TextEditingController(text: currentValue);
    final l10n = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String fieldLabel = _getLabel(l10n, fieldKey);
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF151922),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${l10n.edit} $fieldLabel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                textDirection: fieldKey == 'phone' ? TextDirection.ltr : null,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.new_value(fieldLabel),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _feedbackService.vibrateSelection();
                      Navigator.pop(context);
                    },
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      _feedbackService.vibrateSelection();
                      Navigator.pop(context, controller.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      l10n.save,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      _feedbackService.vibrateLight();
      _feedbackService.playSuccessTone();
      setState(() => onSave(result.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Back Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Back to Settings',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        header: true,
                        label: l10n.account_info,
                        excludeSemantics: false,
                        child: Text(
                          l10n.account_info,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              
              // Profile Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: const Color(0xFF313131),
                ),
              ),
              const SizedBox(height: 30),
              
              // User Info Fields
              _buildInfoField(
                icon: Icons.person,
                text: l10n.name,
                value: userName,
                onEdit: () => _editField('name', userName, (val) => userName = val),
              ),
              _buildInfoField(
                icon: Icons.phone,
                text: l10n.phone,
                value: phoneNumber,
                onEdit: () => _editField('phone', phoneNumber, (val) => phoneNumber = val),
                isPhone: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required String text,
    required String value,
    required VoidCallback onEdit,
    bool isPhone = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onEdit,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25.0),
          leading: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF313131),
              size: 25,
            ),
          ),
          title: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Semantics(
            label: '$text: $value',
            excludeSemantics: false,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              textDirection: isPhone ? TextDirection.ltr : null,
            ),
          ),
          trailing: Icon(
            Icons.edit,
            color: Theme.of(context).primaryColor,
          ),
        ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.0),
              child: Divider(color: Colors.white),
            ),
            const SizedBox(height: 15),
      ],
    );
  }


  String _getLabel(AppLocalizations l10n, String fieldKey) {
    switch (fieldKey) {
      case 'name':
        return l10n.name;
      case 'phone':
        return l10n.phone;
      default:
        return fieldKey;
    }
  }
}
