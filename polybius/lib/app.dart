import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';
import 'package:polybius/features/arcade/screens/load_game_screen.dart';
import 'package:polybius/features/arcade/screens/main_menu_screen.dart';
import 'package:polybius/features/arcade/screens/settings_screen.dart';
import 'package:polybius/features/auth/screens/login_screen.dart';
import 'package:polybius/features/auth/screens/pin_screen.dart';
import 'package:polybius/features/cipher/screens/cipher_shell.dart';
import 'package:polybius/features/game/screens/game_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final unlockState = ref.watch(unlockProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = authState.isAuthenticated;
      final needsPin = authState.needsPin && authState.user != null;

      if (!loggedIn && !needsPin && loc != '/login') return '/login';
      if (needsPin && loc != '/pin') return '/pin';
      if (loggedIn && loc == '/login') return '/menu';
      if (loggedIn && loc == '/pin') return '/menu';

      final cipherUnlocked = unlockState.state == UnlockState.unlocked ||
          unlockState.state == UnlockState.developer;
      if (loc == '/cipher' && !cipherUnlocked) return '/menu';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/pin', builder: (_, __) => const PinScreen()),
      GoRoute(path: '/menu', builder: (_, __) => const MainMenuScreen()),
      GoRoute(path: '/game', builder: (_, __) => const GameScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/load', builder: (_, __) => const LoadGameScreen()),
      GoRoute(path: '/cipher', builder: (_, __) => const CipherShell()),
    ],
  );
});

class PolybiusApp extends ConsumerWidget {
  const PolybiusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final unlock = ref.watch(unlockProvider);

    return MaterialApp.router(
      title: 'PØLYBĪUS',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        if (unlock.fakeCrash) {
          return const _FakeCrashScreen();
        }
        return CrtOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _FakeCrashScreen extends StatelessWidget {
  const _FakeCrashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ':(',
              style: TextStyle(fontSize: 80, color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'POLYBIUS has encountered a problem.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Collecting error information...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
