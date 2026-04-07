import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF060606);
  static const Color primary = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF22C55E);
  static const Color text = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFF0E0E0E);
  static const Color surfaceAlt = Color(0xFF151515);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: text,
      onSecondary: text,
      onSurface: text,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontSize: 56,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -1.5,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -0.8,
        ),
        headlineSmall: TextStyle(
          color: text,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 15,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: Color(0xFFA1A1AA),
          fontSize: 13,
          height: 1.35,
        ),
      ),
      cardTheme: const CardThemeData(
        color: surfaceAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          animationDuration: const Duration(milliseconds: 180),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: text.withValues(alpha: 0.24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
