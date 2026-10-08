import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';
import 'screens/home_shell.dart';
import 'theme/noir_theme.dart';

/// DOØMSDAY BUNKER v1 — SpamKat2 & Gam3.0n privileged build.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DoomsdayBunkerApp());
}

class DoomsdayBunkerApp extends StatelessWidget {
  const DoomsdayBunkerApp({super.key});

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

/// Alias for existing test / import paths.
typedef DoomsdayClockApp = DoomsdayBunkerApp;
