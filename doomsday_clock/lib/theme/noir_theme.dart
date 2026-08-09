import 'package:flutter/material.dart';

/// Neo-noir / cyberpunk palette — not purple-default AI chrome.
class NoirTheme {
  static const ink = Color(0xFF07090C);
  static const panel = Color(0xFF12161C);
  static const line = Color(0xFF2A3340);
  static const mist = Color(0xFFC8D0D8);
  static const cyan = Color(0xFF5EEAD4);
  static const amber = Color(0xFFE8B86D);
  static const orange = Color(0xFFF07A3A);
  static const crimson = Color(0xFFE11D48);
  static const peace = Color(0xFF34D399);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          surface: panel,
          primary: cyan,
          secondary: amber,
          error: crimson,
        ),
        fontFamily: 'RobotoMono',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'serif',
            fontSize: 42,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: mist,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: mist,
          ),
          bodyLarge: TextStyle(fontSize: 15, height: 1.45, color: mist),
          bodyMedium: TextStyle(fontSize: 13, height: 1.4, color: mist),
          labelLarge: TextStyle(
            fontSize: 12,
            letterSpacing: 0.14 * 12,
            fontWeight: FontWeight.w600,
            color: cyan,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
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
