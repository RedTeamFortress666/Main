import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_shell.dart';
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
  const DoomsdayClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOOMSDAY CLOCK 2.0',
      debugShowCheckedModeBanner: false,
      theme: NoirTheme.dark,
      home: const HomeShell(),
    );
  }
}
