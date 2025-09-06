import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/features/auth/presentation/widgets/custom_button.dart';
import 'package:navia/core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:navia/features/main/presentation/screen/main_screen.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';

class SignupVoiceScreen extends StatefulWidget {
  final String name;

  const SignupVoiceScreen({super.key, required this.name});

  @override
  State<SignupVoiceScreen> createState() => _SignupVoiceScreenState();
}

class _SignupVoiceScreenState extends State<SignupVoiceScreen> {
  void _onEnrollPressed() {
    print('الضغط على زر "ابدأ التسجيل"');
    context.read<AuthCubit>().enrollVoice();
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
            if (state is VoiceIdEnrollmentComplete) {
              print(
                'BlocListener: استقبل حالة VoiceIdEnrollmentComplete. الآن سيتم استدعاء وظيفة التسجيل الكاملة...',
              );
              context.read<AuthCubit>().signup(
                widget.name,
                state.voiceProfileUrl,
              );
            } else if (state is AuthSignupSuccess) {
              print(
                'BlocListener: استقبل حالة AuthSignupSuccess بنجاح! سيتم الآن الانتقال إلى شاشة تسجيل الدخول.',
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) =>  MainScreen()),
                (route) => false,
              );
            } else if (state is AuthError) {
              print(
                'BlocListener: استقبل حالة AuthError. حدث خطأ في التسجيل: ${state.message}',
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            } else {
              print('BlocListener: استقبل حالة أخرى: ${state.runtimeType}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizations.recordYourVoice,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  localizations.voiceEnrollmentMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                CustomButton(
                  text: localizations.startRecording,
                  onPressed: _onEnrollPressed,
                ),
                const SizedBox(height: 20),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is VoiceIdEnrollmentStarted) {
                      return const CircularProgressIndicator();
                    } else if (state is VoiceIdEnrollmentComplete) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text(
                            localizations.completingSignup,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      );
                    } else if (state is VoiceIdEnrollmentError) {
                      return Text(
                        state.message,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                        ),
                      );
                    } else if (state is AuthError) {
                      return Text(
                        localizations.signupError(state.message),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
