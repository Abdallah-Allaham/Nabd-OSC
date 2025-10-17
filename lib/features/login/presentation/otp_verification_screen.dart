import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/core/services/feedback_service.dart';
import 'package:navia/core/theme/app_theme.dart';
import 'package:navia/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:navia/features/auth/presentation/widgets/custom_button.dart';
import 'package:navia/features/auth/presentation/widgets/speech_input_button.dart';
import 'package:navia/features/auth/presentation/widgets/otp_text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../../l10n/app_localizations.dart';

import '../../main/presentation/screen/main_screen.dart';
import '../../../../core/utils/permissions_helper.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({super.key, this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final feedback = FeedbackService();
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
    final otp = _otpController.text;
    if (otp.isEmpty) {
      feedback.playFailureTone();
      feedback.announce('يرجى إدخال رمز التحقق', context);
      feedback.vibrateHeavy();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى إدخال رمز التحقق')),
      );
      return;
    }

    feedback.playLoadingTone();
    feedback.announce('جاري التحقق من الرمز', context);

    context.read<AuthCubit>().verifyOtp(otp);
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
            if (state is AuthAuthenticatedForLogin) {
              feedback.playSuccessTone();
              feedback.announce('تم تسجيل الدخول بنجاح', context);
              feedback.vibrateLight();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
                (route) => false,
              );
            } else if (state is AuthError) {
              feedback.playFailureTone();
              feedback.announce(state.message, context);
              feedback.vibrateHeavy();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthSpeechComplete) {
              if (state.recognizedText.isNotEmpty) {
                final String digitsOnly = state.recognizedText.replaceAll(RegExp(r'\D'), '');
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
                Semantics(
                  label: localizations.otpScreenSemantics,
                  child: const SizedBox.shrink(),
                ),
                Text(
                  localizations.otpVerificationTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  localizations.otpMessage,
                  style: textTheme.bodyMedium,
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
