import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/features/signup/presentation/signup_otp_verification_screen.dart';
import 'package:navia/core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_constants.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/widgets/custom_button.dart';
import '../../auth/presentation/widgets/speech_input_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_phoneController.text.length == 10) {
        _onSignupPressed();
      }
    });
  }

  void _onSignupPressed() {
    final phoneNumber = _phoneController.text.replaceAll(' ', '');
    if (!jordanianPhoneNumberRegex.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.invalidPhoneNumber)));
      return;
    }

    if (phoneNumber.isNotEmpty) {
      context.read<AuthCubit>().signUpWithPhoneNumber(phoneNumber);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(gradient: appGradient?.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthOtpSentForSignup) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SignupOtpVerificationScreen(
                    phoneNumber: state.phoneNumber,
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
                Text(
                  localizations.createAccount,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 50),
                SpeechInputButton(),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  maxLength: 10,
                  style: Theme.of(context).textTheme.bodyLarge,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: localizations.enterPhoneNumberManually,
                    labelStyle: Theme.of(context).textTheme.bodyLarge,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),
                CustomButton(text: localizations.signup, onPressed: _onSignupPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
