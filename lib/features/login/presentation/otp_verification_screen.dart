import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/core/theme/app_theme.dart';
import 'package:navia/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:navia/features/auth/presentation/widgets/custom_button.dart';
import 'package:navia/features/auth/presentation/widgets/speech_input_button.dart';
import 'package:navia/features/auth/presentation/widgets/otp_text_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../auth/presentation/screens/main_screen.dart';
import '../../../../core/utils/permissions_helper.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const OtpVerificationScreen({super.key, this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
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
        const SnackBar(
          content: Text('الرجاء السماح بقراءة الرسائل لتفعيل الملء التلقائي.'),
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
    if (otp.isNotEmpty) {
      context.read<AuthCubit>().verifyOtp(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticatedForLogin) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AuthSpeechResult) {
              if (state.recognizedText.isNotEmpty) {
                String cleanedResult =
                    state.recognizedText.replaceAll(' ', '').trim();
                setState(() {
                  _otpController.text = cleanedResult;
                });
                SemanticsService.announce(
                  'تم إدخال الرمز: ${_otpController.text}',
                  TextDirection.rtl,
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
                  label:
                      'صفحة التحقق من الرمز السري، أدخل رمز التحقق عن طريق الكلام أو الكتابة.',
                  child: const SizedBox.shrink(),
                ),
                Text(
                  'تحقق من الرمز السري',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  'لقد أرسلنا رمز التحقق إلى رقم هاتفك.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                SpeechInputButton(),
                const SizedBox(height: 20),
                OtpTextField(controller: _otpController),
                const SizedBox(height: 20),
                CustomButton(text: 'تحقق', onPressed: _onVerifyPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
