import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';
import 'screens/home_shell.dart';
import 'theme/noir_theme.dart';

/// DOØMSDAY CLØCK (stable) — any-tier accounts + QR vault scan.
void main() {
  AppConfig.enableStableRuntime();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DoomsdayClockStableApp());
}

class DoomsdayClockStableApp extends StatelessWidget {
  const DoomsdayClockStableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.displayName,
      debugShowCheckedModeBanner: false,
      theme: NoirTheme.dark,
      home: const HomeShell(),
    );
  }
}
