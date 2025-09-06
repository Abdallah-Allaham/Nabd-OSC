import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/features/auth/presentation/widgets/custom_button.dart';
import 'package:navia/features/signup/presentation/signup_voice_screen.dart';
import 'package:navia/features/auth/presentation/widgets/speech_input_button.dart';
import 'package:navia/core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';

class SignupNameScreen extends StatefulWidget {
  const SignupNameScreen({super.key});

  @override
  State<SignupNameScreen> createState() => _SignupNameScreenState();
}

class _SignupNameScreenState extends State<SignupNameScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _onNextPressed() {
    if (_nameController.text.isNotEmpty) {
      context.read<AuthCubit>().setUserName(_nameController.text);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupVoiceScreen(name: _nameController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthSpeechComplete) {
              if (state.recognizedText.isNotEmpty) {
                setState(() {
                  _nameController.text = state.recognizedText;
                });
                SemanticsService.announce(
                  localizations.nameEntered(_nameController.text),
                  Directionality.of(context),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.enterYourName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),
                SpeechInputButton(),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: localizations.enterNameManually,
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(text: localizations.next, onPressed: _onNextPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
