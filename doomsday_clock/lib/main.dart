import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/journal_screen.dart';
import 'theme/noir_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const DoomsdayClockApp());
}

class DoomsdayClockApp extends StatelessWidget {
  const DoomsdayClockApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Døømsday Journal',
      debugShowCheckedModeBanner: false,
      theme: NoirTheme.dark,
      home: home ?? const JournalScreen(),
    );
  }
}
