import 'package:flutter/material.dart';

/// Cyberpunk neon palette for DOOMSDAY CLOCK 2.1.
class NoirTheme {
  static const voidBlack = Color(0xFF05000C);
  static const ink = Color(0xFF0A0014);
  static const panel = Color(0xFF120820);
  static const mist = Color(0xFFE8E0FF);
  static const matrix = Color(0xFF39FF14);
  static const neonCyan = Color(0xFF00F0FF);
  static const neonMagenta = Color(0xFFFF00AA);
  static const cyan = neonCyan;
  static const amber = Color(0xFFFFB347);
  static const orange = Color(0xFFFF6B2B);
  static const crimson = Color(0xFFFF1744);
  static const pink = neonMagenta;
  static const yellow = Color(0xFFFFF200);
  static const peace = Color(0xFF34D399);
  static const chrome = Color(0xFF8A9BB5);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          surface: panel,
          primary: neonCyan,
          secondary: neonMagenta,
          error: crimson,
        ),
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'monospace',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: neonCyan,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: mist,
            letterSpacing: 1.2,
          ),
          bodyLarge: TextStyle(fontSize: 14, height: 1.45, color: mist),
          bodyMedium: TextStyle(fontSize: 12, height: 1.4, color: mist),
          labelLarge: TextStyle(
            fontSize: 10,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w700,
            color: neonMagenta,
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
