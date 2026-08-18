import 'package:flutter/material.dart';

class NoirTheme {
  static const voidBlack = Color(0xFF05000C);
  static const ink = Color(0xFF0A0014);
  static const panel = Color(0xFF120820);
  static const mist = Color(0xFFE8E0FF);
  static const neonCyan = Color(0xFF00F0FF);
  static const neonMagenta = Color(0xFFFF00AA);
  static const amber = Color(0xFFFFB347);
  static const crimson = Color(0xFFFF1744);
  static const yellow = Color(0xFFFFF200);
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
            fontSize: 22,
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
}
