import 'package:flutter/material.dart';

/// Heavy neon / matrix palette for DOOMSDAY CLOCK 2.0.
class NoirTheme {
  static const ink = Color(0xFF020403);
  static const panel = Color(0xFF07110C);
  static const line = Color(0xFF1AFF80);
  static const mist = Color(0xFFD7FFE8);
  static const matrix = Color(0xFF39FF14);
  static const cyan = Color(0xFF5EEAD4);
  static const amber = Color(0xFFE8B86D);
  static const orange = Color(0xFFF07A3A);
  static const crimson = Color(0xFFFF1744);
  static const pink = Color(0xFFFF2D95);
  static const yellow = Color(0xFFFFF200);
  static const peace = Color(0xFF34D399);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          surface: panel,
          primary: matrix,
          secondary: pink,
          error: crimson,
        ),
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'monospace',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: matrix,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: mist,
          ),
          bodyLarge: TextStyle(fontSize: 14, height: 1.45, color: mist),
          bodyMedium: TextStyle(fontSize: 12, height: 1.4, color: mist),
          labelLarge: TextStyle(
            fontSize: 11,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w700,
            color: matrix,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        useMaterial3: true,
      );

  static Color threatColor(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.peace:
        return peace;
      case ThreatLevel.tension:
        return amber;
      case ThreatLevel.crisis:
        return orange;
      case ThreatLevel.conflict:
        return crimson;
    }
  }
}

enum ThreatLevel { peace, tension, crisis, conflict }
