import 'package:flutter/material.dart';

/// Dark mesh aesthetic aligned with PØLYBĪUS neon cyberpunk palette.
class ShadowTheme {
  static const Color background = Color(0xFF050810);
  static const Color surface = Color(0xFF0D1220);
  static const Color surfaceHigh = Color(0xFF151C2E);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color neonGreen = Color(0xFF00FF9C);
  static const Color neonAmber = Color(0xFFFFB800);
  static const Color dangerRed = Color(0xFFFF3366);
  static const Color qshieldBlue = Color(0xFF4CC9F0);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: neonCyan,
          secondary: neonPurple,
          surface: surface,
          error: dangerRed,
        ),
        fontFamily: 'monospace',
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: neonCyan,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surfaceHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: neonCyan.withValues(alpha: 0.25)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: neonCyan.withValues(alpha: 0.4)),
          ),
          labelStyle: const TextStyle(color: neonGreen),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 22,
            color: neonCyan,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            color: neonGreen,
            letterSpacing: 1,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          labelLarge: TextStyle(
            fontSize: 12,
            color: neonAmber,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}
