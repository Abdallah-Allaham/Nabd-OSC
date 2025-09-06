import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/features/signup/presentation/signup_name_screen.dart';
import 'package:navia/features/auth/presentation/widgets/otp_text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:navia/core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../auth/presentation/widgets/custom_button.dart';
import '../../auth/presentation/widgets/speech_input_button.dart';
import '../../../../core/utils/permissions_helper.dart';

class SignupOtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const SignupOtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<SignupOtpVerificationScreen> createState() =>
      _SignupOtpVerificationScreenState();
}

class _SignupOtpVerificationScreenState
    extends State<SignupOtpVerificationScreen>
    with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listenForCode();
  }

  void _listenForCode() async {
    final isGranted = await PermissionsHelper.requestPermission(Permission.sms);
    if (isGranted) {
      await SmsAutoFill().listenForCode;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.smsPermissionMessage),
        ),
      );
    }
  }

  @override
  void codeUpdated() {
    setState(() {
      _otpController.text = code ?? '';
    });
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  void _onVerifyPressed() {
    if (_otpController.text.isNotEmpty) {
      context.read<AuthCubit>().verifyOtp(_otpController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.otpVerificationTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.phoneVerified)),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignupNameScreen(),
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthSpeechComplete) {
              if (state.recognizedText.isNotEmpty) {
                final String digitsOnly = state.recognizedText.replaceAll(RegExp(r'\\D'), '');
                setState(() {
                  _otpController.text = digitsOnly;
                });
                SemanticsService.announce(
                  localizations.codeEntered(digitsOnly),
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
                  localizations.otpMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                SpeechInputButton(),
                const SizedBox(height: 20),
                OtpTextField(controller: _otpController),
                const SizedBox(height: 20),
                CustomButton(text: localizations.verify, onPressed: _onVerifyPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
