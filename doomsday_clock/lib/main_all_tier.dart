import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';
import 'screens/home_shell.dart';
import 'theme/noir_theme.dart';

/// All-tier build entry — local accounts + QR vault scan.
void main() {
  AppConfig.enableAllTierRuntime();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DoomsdayClockAllTierApp());
}

class DoomsdayClockAllTierApp extends StatelessWidget {
  const DoomsdayClockAllTierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOØMSDAY CLØCK · ALL TIER',
      debugShowCheckedModeBanner: false,
      theme: NoirTheme.dark,
      home: const HomeShell(),
    );
  }
}
