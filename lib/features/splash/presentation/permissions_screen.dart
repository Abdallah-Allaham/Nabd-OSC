import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../login/presentation/phone_number_screen.dart';
import '../../main/presentation/screen/main_screen.dart';

const _platform = MethodChannel('nabd/foreground');

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  void _handleNavigation(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      FeedbackService().playSuccessTone();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) =>  MainScreen()),
        (route) => false,
      );
    } else if (state is AuthUnauthenticated) {
      FeedbackService().playFailureTone();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
      );
    } else {
      context.read<AuthCubit>().checkAuthStatus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNavigation(context);
      });
    }
  }

  Future<void> _requestPermissions(BuildContext context) async {
    try {
      await _platform.invokeMethod('requestBatteryOptimization');
      await _platform.invokeMethod('requestOverlayPermission');
      await _platform.invokeMethod('requestAccessibilityPermission');
      FeedbackService().playSuccessTone();

      _handleNavigation(context);
    } on PlatformException catch (e) {
      FeedbackService().playFailureTone();
      FeedbackService().vibrate();
      _handleNavigation(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();
    final appColors = Theme.of(context).extension<AppColor>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.power_settings_new,
                size: 80,
                color: appColors?.textLight,
              ),
              const SizedBox(height: 24),
              Text(
                localizations.alert,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                localizations.permissionsMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _requestPermissions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors?.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  localizations.grantPermissions,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  FeedbackService().playFailureTone();
                  _handleNavigation(context);
                },
                child: Text(
                  localizations.ignore,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: appColors?.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
