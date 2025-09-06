import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/widgets/custom_button.dart';
import '../../auth/presentation/widgets/speech_input_button.dart';
import '../../signup/presentation/signup_screen.dart';
import 'otp_verification_screen.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_phoneController.text.length == 10) {
        _onVerifyPressed();
      }
    });
  }

  void _onVerifyPressed() {
    final phoneNumber = _phoneController.text.replaceAll(' ', '');
    if (!jordanianPhoneNumberRegex.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.invalidPhoneNumber)));
      return;
    }

    if (phoneNumber.isNotEmpty) {
      context.read<AuthCubit>().signInWithPhoneNumber(phoneNumber);
    }
  }

  void _onSignupPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthOtpSentForLogin) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => OtpVerificationScreen(
                    phoneNumber: _phoneController.text,
                  ),
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthSpeechComplete) {
              if (state.recognizedText.isNotEmpty) {
                final String digitsOnly = state.recognizedText.replaceAll(RegExp(r'\D'), '');
                final String limited = digitsOnly.length > 10 ? digitsOnly.substring(0, 10) : digitsOnly;
                setState(() {
                  _phoneController.text = limited;
                });
                SemanticsService.announce(
                  localizations.phoneNumberEntered(limited),
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
                const Spacer(),
                Semantics(
                  label: localizations.loginPageSemantics,
                  child: const SizedBox.shrink(),
                ),
                Text(
                  localizations.loginTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),
                SpeechInputButton(),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  style: textTheme.bodyLarge,
                  maxLength: 10,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: localizations.enterPhoneNumberManually,
                    labelStyle: textTheme.bodyLarge,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),
                CustomButton(text: localizations.verify, onPressed: _onVerifyPressed),
                const Spacer(),
                CustomButton(
                  text: localizations.createAccount,
                  onPressed: _onSignupPressed,
                  isSecondary: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
