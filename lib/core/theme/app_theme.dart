import 'package:flutter/material.dart';

class AppColor extends ThemeExtension<AppColor> {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color textLight;
  final Color background;

  const AppColor({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.textLight,
    required this.background,
  });

  @override
  AppColor copyWith({
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? textLight,
    Color? background,
  }) {
    return AppColor(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      textLight: textLight ?? this.textLight,
      background: background ?? this.background,
    );
  }

  @override
  AppColor lerp(ThemeExtension<AppColor>? other, double t) {
    if (other is! AppColor) return this;
    return AppColor(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      background: Color.lerp(background, other.background, t)!,
    );
  }
}

class AppGradient extends ThemeExtension<AppGradient> {
  final LinearGradient background;

  const AppGradient({required this.background});

  @override
  AppGradient copyWith({LinearGradient? background}) {
    return AppGradient(background: background ?? this.background);
  }

  @override
  AppGradient lerp(ThemeExtension<AppGradient>? other, double t) {
    if (other is! AppGradient) return this;
    return AppGradient(
      background: LinearGradient.lerp(background, other.background, t)!,
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF151922);
  static const Color secondary = Color(0xFF0A286D);
  static const Color accent = Color(0xFF354B94);
  static const Color textLight = Colors.white;
  static const Color background = Color(0xFF041235);
  static const Color error = Colors.red;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.black87;

  static const LinearGradient mainGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData lightTheme = ThemeData(
    extensions: <ThemeExtension<dynamic>>[
      const AppColor(
        primary: primary,
        secondary: secondary,
        accent: accent,
        textLight: textLight,
        background: background,
      ),
      const AppGradient(background: mainGradient),
    ],
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textLight),
      bodyMedium: TextStyle(color: textLight),
      titleLarge: TextStyle(color: textLight),
      titleMedium: TextStyle(color: textLight),
      labelLarge: TextStyle(color: textLight),
    ),
    iconTheme: const IconThemeData(color: textLight),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
