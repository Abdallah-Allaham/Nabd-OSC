import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/core/utils/permissions_helper.dart';
import 'package:permission_handler/permission_handler.dart';


import '../../../../l10n/app_localizations.dart';
import '../cubit/auth_cubit.dart';

class SpeechInputButton extends StatelessWidget {
  const SpeechInputButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        final bool isListening =
            state is AuthListeningForSpeech ||
            state is AuthSpeechResult ||
            state is AuthSpeechComplete;

        return Semantics(
          label: AppLocalizations.of(context)!.microphoneOn,
          button: true,
          child: GestureDetector(
            onTap: () async {
              final isGranted = await PermissionsHelper.requestPermission(
                Permission.microphone,
              );

              if (isGranted) {
                if (isListening) {
                  context.read<AuthCubit>().stopSpeechToText();
                } else {
                  context.read<AuthCubit>().toggleSpeechToText();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.smsPermissionMessage,
                    ),
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isListening ? Colors.redAccent : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isListening
                    ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ]
                    : null,
              ),
              child: Icon(
                Icons.mic,
                color: isListening ? Colors.white : Colors.black54,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}

