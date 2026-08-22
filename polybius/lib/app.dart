import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/audio/music_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/routing/router_refresh.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';
import 'package:polybius/core/widgets/splash_screen.dart';
import 'package:polybius/features/arcade/screens/high_score_screen.dart';
import 'package:polybius/features/arcade/screens/load_game_screen.dart';
import 'package:polybius/features/arcade/screens/main_menu_screen.dart';
import 'package:polybius/features/arcade/screens/settings_screen.dart';
import 'package:polybius/features/auth/screens/dev_portal_screen.dart';
import 'package:polybius/features/auth/screens/error_screen.dart';
import 'package:polybius/features/auth/screens/login_screen.dart';
import 'package:polybius/features/auth/screens/pin_screen.dart';
import 'package:polybius/features/auth/screens/register_screen.dart';
import 'package:polybius/features/cipher/screens/cipher_shell.dart';
import 'package:polybius/features/clock/screens/cherry_desk_screen.dart';
import 'package:polybius/features/clock/screens/clock_face_screen.dart';
import 'package:polybius/features/clock/screens/clock_gate_screen.dart';
import 'package:polybius/features/clock/screens/clock_keys_screen.dart';
import 'package:polybius/features/game/screens/game_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final unlockState = ref.read(unlockProvider);
      final loc = state.matchedLocation;

      // Keep the splash visible until session restore completes.
      if (authState.isRestoring) {
        return loc == '/' ? null : '/';
      }

      final loggedIn = authState.isAuthenticated;
      final needsPin = authState.needsPin && authState.user != null;

      // Route away from the splash once restore has finished.
      if (loc == '/') {
        if (needsPin) return '/pin';
        return loggedIn ? '/menu' : '/login';
      }

      final onClock = loc == '/clock' || loc.startsWith('/clock/');

      if (!loggedIn &&
          !needsPin &&
          loc != '/login' &&
          loc != '/register' &&
          !onClock) {
        return '/login';
      }
      if (needsPin && loc != '/pin') return '/pin';
      if (loggedIn && loc == '/login') return '/menu';
      if (loggedIn && loc == '/pin') return '/menu';

      final cipherUnlocked = unlockState.state == UnlockState.unlocked ||
          unlockState.state == UnlockState.developer;
      if (loc == '/cipher' && !cipherUnlocked) return '/menu';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
      GoRoute(path: '/menu', builder: (_, _) => const MainMenuScreen()),
      GoRoute(path: '/game', builder: (_, _) => const GameScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/load', builder: (_, _) => const LoadGameScreen()),
      GoRoute(path: '/highscore', builder: (_, _) => const HighScoreScreen()),
      GoRoute(path: '/devportal', builder: (_, _) => const DevPortalScreen()),
      GoRoute(path: '/error', builder: (_, _) => const ErrorScreen()),
      GoRoute(path: '/cipher', builder: (_, _) => const CipherShell()),
      GoRoute(path: '/clock', builder: (_, _) => const ClockGateScreen()),
      GoRoute(path: '/clock/face', builder: (_, _) => const ClockFaceScreen()),
      GoRoute(path: '/clock/desk', builder: (_, _) => const CherryDeskScreen()),
      GoRoute(path: '/clock/keys', builder: (_, _) => const ClockKeysScreen()),
    ],
  );
});

class PolybiusApp extends ConsumerStatefulWidget {
  const PolybiusApp({super.key});

  @override
  ConsumerState<PolybiusApp> createState() => _PolybiusAppState();
}

class _PolybiusAppState extends ConsumerState<PolybiusApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final enabled = ref.read(gameSettingsProvider).soundEnabled;
      ref.read(musicServiceProvider).setEnabled(enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Note: logging in does NOT auto-open the cipher. The crypto engine is
    // reachable only via the dev access portal with a valid access code.

    // Start/stop the soundtrack when the sound setting changes.
    ref.listen(gameSettingsProvider.select((s) => s.soundEnabled), (_, enabled) {
      ref.read(musicServiceProvider).setEnabled(enabled);
    });

    final router = ref.watch(routerProvider);
    final unlock = ref.watch(unlockProvider);

    return MaterialApp.router(
      title: 'PØLYBĪUS',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        if (unlock.fakeCrash) {
          return _FakeCrashScreen(
            onDismiss: () =>
                ref.read(unlockProvider.notifier).dismissFakeCrash(),
          );
        }
        return CrtOverlay(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _FakeCrashScreen extends StatelessWidget {
  const _FakeCrashScreen({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: const Scaffold(
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
              SizedBox(height: 24),
              Text(
                'Tap to continue',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
