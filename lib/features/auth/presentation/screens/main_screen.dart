import 'package:flutter/material.dart';
import 'package:navia/core/theme/app_theme.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: appGradient?.background),
        child: Center(
          child: Text(
            'مرحباً بك في التطبيق!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold,color: AppTheme.textLight),
          ),
        ),
      ),
    );
  }
}
