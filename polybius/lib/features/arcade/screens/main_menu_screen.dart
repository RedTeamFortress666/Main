import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

/// Layer 2 public face — retro arcade main menu with hidden unlock rituals.
///
/// Ritual entry point: hold the PØLYBĪUS title for 6 seconds until it
/// glitches, which primes the hidden pathway (see [SettingsScreen] for the
/// difficulty-11 + Russian-hold continuation).
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  Timer? _holdTimer;
  bool _holding = false;
  int _debugTitleTaps = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startTitleHold() {
    setState(() => _holding = true);
    ref.read(unlockProvider.notifier).onTitleHoldStart();
    _holdTimer = Timer(
      const Duration(milliseconds: AppConstants.devTitleHoldMs),
      () {
        if (_holding) {
          ref.read(unlockProvider.notifier).onTitleHoldComplete();
        }
      },
    );
  }

  void _endTitleHold() {
    setState(() => _holding = false);
    _holdTimer?.cancel();
  }

  void _onDebugTitleTap() {
    if (!kDebugMode) return;
    _debugTitleTaps++;
    if (_debugTitleTaps >= 6) {
      _debugTitleTaps = 0;
      ref.read(unlockProvider.notifier).onTitleHoldComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlock = ref.watch(unlockProvider);
    final settings = ref.watch(gameSettingsProvider);
    final auth = ref.watch(authProvider);

    return GlitchOverlay(
      active: unlock.showGlitch,
      onComplete: () => ref.read(unlockProvider.notifier).onGlitchComplete(),
      child: ArcadeScaffold(
        child: Stack(
          children: [
            SubliminalFlash(phrases: AppConstants.mkUltraPhrases),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
              children: [
                const Spacer(),
                Listener(
                  onPointerDown: (_) => _startTitleHold(),
                  onPointerUp: (_) => _endTitleHold(),
                  onPointerCancel: (_) => _endTitleHold(),
                  child: GestureDetector(
                    onTap: _onDebugTitleTap,
                    child: ArcadeTitle(
                      color:
                          _holding ? NeonTheme.neonYellow : NeonTheme.neonPink,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: _pulse,
                  child: const Text(
                    '► INSERT COIN ◄',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: NeonTheme.neonYellow,
                      letterSpacing: 4,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                ArcadeMenuButton(
                  label: 'START GAME',
                  color: NeonTheme.neonGreen,
                  onPressed: () => context.push('/game'),
                ),
                ArcadeMenuButton(
                  label: 'LOAD GAME',
                  color: NeonTheme.neonCyan,
                  onPressed: () => context.push('/load'),
                ),
                ArcadeMenuButton(
                  label: 'HIGH SCORE',
                  color: NeonTheme.neonPurple,
                  onPressed: () => context.push('/highscore'),
                ),
                ArcadeMenuButton(
                  label: 'SETTINGS',
                  color: NeonTheme.neonOrange,
                  onPressed: () => context.push('/settings'),
                ),
                // No cipher entry on the start screen for any build: the crypto
                // engine is reachable only via the dev access portal login.
                const Spacer(),
                if (kDebugMode)
                  Text(
                    'DEV: ${auth.user?.username ?? "?"} | '
                    '${settings.language} | D:${settings.difficulty} | '
                    'primed:${unlock.pathwayPrimed}',
                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                const SizedBox(height: 8),
              ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
