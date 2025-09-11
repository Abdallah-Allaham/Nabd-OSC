import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/voice_handlers/voice_handler_language.dart';
import '../../../main/presentation/voice/chat_compilation_loader.dart';
import '../../../main/presentation/voice/voice_router.dart';
import '../../../profile/presentation/screen/Profile_screen.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../login/presentation/phone_number_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../widget/language_dialog.dart';

class SettingScreen extends StatefulWidget {
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late bool isArabic;
  late VoiceRouter voiceRouter;
  late ChatCompilationLoader loader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String lang = Localizations.localeOf(context).languageCode;
    loader = ChatCompilationLoader(lang);
    voiceRouter = VoiceRouter(loader);
  }

  Future<void> _logout() async {
    try {
      await context.read<AuthCubit>().logout();
      // Navigate to login screen after logout
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PhoneNumberScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void handleVoiceIntent(Map<String, dynamic> intent) {
    final id = intent['id'];
    switch (id) {
      case 'settings.open_account':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }

  Future<void> onVoiceCommand(String userText) async {
    final output = await voiceRouter.route(userText, currentPage: 'settings');
    if (output['type'] == 'page' && output['data'] != null) {
      final intent = output['data'];
      if (await LanguageVoiceHandler.handle(context, intent)) return;

      handleVoiceIntent(intent);
    } else if (output['type'] == 'unknown') {
      print('لم أفهم، أعد الكلام');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Semantics(
              header: true,
              label: AppLocalizations.of(context)!.setting,
              excludeSemantics: false,
              child: Text(
                AppLocalizations.of(context)!.setting,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 120),
            _buildSettingsOption(
              icon: Icons.person,
              text: AppLocalizations.of(context)!.profile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            _buildSettingsOption(
              icon: Icons.language,
              text: AppLocalizations.of(context)!.switch_language,
              onTap: () => LanguageDialog.show(context), // تم التبديل هنا
            ),
            _buildSettingsOption(
              icon: Icons.logout,
              text: AppLocalizations.of(context)!.logout,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
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
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: Divider(color: Colors.white),
        ),
      ],
    );
  }
}
