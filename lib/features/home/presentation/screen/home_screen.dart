import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../guidance/presentation/screen/guidance_screen.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.secondary, AppTheme.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Semantics(
              header: true,
              label: AppLocalizations.of(context)!.home,
              child: Text(
                AppLocalizations.of(context)!.home,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 180),
            const CircleAvatar(
              radius: 110,
              backgroundColor: Colors.black,
            ),
            const SizedBox(height: 80),
            Container(
              width: 100,
              height: 98,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GuidanceScreen()),
                      );
                      // التأكد من إغلاق الكاميرا عند العودة
                      print("📱 Returned from camera screen");
                    },
                    icon: Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    iconSize: 34,
                  ),                  const SizedBox(height: 2),
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF0A286B),
                    child: Icon(Icons.add, color: Colors.white, size: 23),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
