import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/core/services/feedback_service.dart';
import 'package:navia/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';

import '../../main/presentation/screen/main_screen.dart';
import '../../login/presentation/phone_number_screen.dart';
import 'permissions_screen.dart';
import 'package:navia/core/theme/app_theme.dart';

const _platform = MethodChannel('nabd/foreground');

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textUpController;
  late Animation<Offset> _textUpAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _textRightAnimation;

  @override
  void initState() {
    super.initState();

    _textUpController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.7),
      end: const Offset(0, 0.2),
    ).animate(
      CurvedAnimation(parent: _textUpController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _textRightAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0),
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _textUpController.forward().then((_) {
      checkPermissionsAndNavigate();
    });

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final state = context.read<AuthCubit>().state;
        if (state is AuthAuthenticated) {
          FeedbackService().playSuccessTone();
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => MainScreen(),
              transitionsBuilder:
                  (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (route) => false,
          );
        } else if (state is AuthUnauthenticated) {
          FeedbackService().playFailureTone();
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const PhoneNumberScreen(),
              transitionsBuilder:
                  (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    FeedbackService().announce(
      AppLocalizations.of(context)!.welcomeMessage,
      context,
    );
  }

  Future<void> checkPermissionsAndNavigate() async {
    try {
      final isBatteryIgnored = await _platform.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );
      final isOverlayEnabled = await _platform.invokeMethod('isOverlayEnabled');
      final isAccessibilityEnabled = await _platform.invokeMethod(
        'isAccessibilityEnabled',
      );

      if (isBatteryIgnored && isOverlayEnabled && isAccessibilityEnabled) {
        context.read<AuthCubit>().checkAuthStatus();
      } else {
        FeedbackService().playFailureTone();
        FeedbackService().vibrate();
        _fadeController.forward().then((_) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const PermissionsScreen(),
              transitionsBuilder:
                  (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        });
      }
    } on PlatformException catch (e) {
      FeedbackService().playFailureTone();
      FeedbackService().vibrate();
      _fadeController.forward().then((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PermissionsScreen(),
            transitionsBuilder:
                (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _textUpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated || state is AuthUnauthenticated) {
              _fadeController.forward();
            }
          },
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Stack(
                children: [
                  ExcludeSemantics(
                    child: Align(
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/logo_dark.png',
                        width: 220,
                        height: 220,
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SlideTransition(
                        position: _textUpAnimation,
                        child: SlideTransition(
                          position: _textRightAnimation,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 80.0),
                            child: Text(
                              AppLocalizations.of(context)!.appName,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                shadows: [
                                  const Shadow(
                                    color: Colors.white54,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
