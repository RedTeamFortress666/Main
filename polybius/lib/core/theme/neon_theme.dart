import 'package:flutter/material.dart';

class NeonTheme {
  static const Color background = Color(0xFF0A0014);
  static const Color surface = Color(0xFF120020);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonOrange = Color(0xFFFF6600);
  static const Color neonPurple = Color(0xFFBF00FF);
  static const Color dangerRed = Color(0xFFFF0040);
  static const Color cherry = Color(0xFFFF1A4A);
  static const Color cherryDeep = Color(0xFF3A0010);
  static const Color scanline = Color(0x22000000);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: neonCyan,
          secondary: neonPink,
          surface: surface,
          error: dangerRed,
        ),
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: neonPink,
            letterSpacing: 4,
            shadows: [
              Shadow(color: neonCyan, blurRadius: 20),
              Shadow(color: neonPink, blurRadius: 40),
            ],
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            color: neonCyan,
            letterSpacing: 2,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: neonGreen),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
          labelLarge: TextStyle(
            fontSize: 14,
            color: neonYellow,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: neonCyan,
            side: const BorderSide(color: neonCyan, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: neonPink,
          inactiveTrackColor: Color(0xFF330033),
          thumbColor: neonCyan,
          overlayColor: Color(0x3300FFFF),
        ),
      );
}
