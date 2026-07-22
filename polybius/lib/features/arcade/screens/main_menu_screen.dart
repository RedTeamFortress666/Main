import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

/// Layer 2 public face — retro arcade main menu with hidden unlock rituals.
///
/// Unlock rituals:
/// - Hold title "PØLYBĪUS" for 3 seconds → glitch + hint state
/// - SETTINGS difficulty 11 + ENGLISH → partial unlock
/// - SETTINGS difficulty 7 + RUSSIAN → full cipher unlock
/// - LOAD GAME with valid invite or dev codes (B1-66-3R / D1-66-3R + CHINESE)
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _starController;
  Timer? _holdTimer;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _startTitleHold() {
    _holding = true;
    ref.read(unlockProvider.notifier).onTitleHoldStart();
    _holdTimer = Timer(
      const Duration(milliseconds: AppConstants.titleHoldMs),
      () {
        if (_holding) {
          ref.read(unlockProvider.notifier).onTitleHoldComplete();
          ref.read(unlockProvider.notifier).triggerFakeCrash();
        }
      },
    );
  }

  void _endTitleHold() {
    _holding = false;
    _holdTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final unlock = ref.watch(unlockProvider);
    final settings = ref.watch(gameSettingsProvider);
    final auth = ref.watch(authProvider);

    ref.listen(unlockProvider, (prev, next) {
      if (next.showGlitch) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && next.state.index >= UnlockState.partial.index) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  next.state == UnlockState.developer
                      ? '◈ DEV CHANNEL OPEN ◈'
                      : '◈ SIGNAL INTERCEPTED ◈',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                backgroundColor: NeonTheme.neonPurple,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    });

    return GlitchOverlay(
      active: unlock.showGlitch,
      onComplete: () => ref.read(unlockProvider.notifier).onGlitchComplete(),
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _starController,
              builder: (context, _) => CustomPaint(
                painter: _StarfieldPainter(_starController.value),
                size: Size.infinite,
              ),
            ),
            SubliminalFlash(phrases: AppConstants.mkUltraPhrases),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onLongPressStart: (_) => _startTitleHold(),
                    onLongPressEnd: (_) => _endTitleHold(),
                    onLongPressCancel: _endTitleHold,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + _pulseController.value * 0.05;
                        return Transform.scale(
                          scale: _holding ? scale * 1.1 : scale,
                          child: child,
                        );
                      },
                      child: Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: _holding
                                  ? NeonTheme.neonYellow
                                  : NeonTheme.neonPink,
                            ),
                      ),
                    ),
                  ),
                  if (unlock.state != UnlockState.locked)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '◈ ${unlock.state.name.toUpperCase()} ◈',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: NeonTheme.neonGreen.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'INSERT COIN',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: NeonTheme.neonYellow,
                        ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Column(
                      children: [
                        NeonButton(
                          label: '▶ START GAME',
                          onPressed: () => context.push('/game'),
                          color: NeonTheme.neonGreen,
                        ),
                        NeonButton(
                          label: '💾 LOAD GAME',
                          onPressed: () => context.push('/load'),
                          color: NeonTheme.neonCyan,
                        ),
                        NeonButton(
                          label: '🏆 HIGH SCORE',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('NO DATA ON FILE'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          color: NeonTheme.neonOrange,
                        ),
                        NeonButton(
                          label: '⚙ SETTINGS',
                          onPressed: () async {
                            await context.push('/settings');
                            final s = ref.read(gameSettingsProvider);
                            ref.read(unlockProvider.notifier).checkDifficultyRitual(s);
                          },
                          color: NeonTheme.neonPink,
                        ),
                        if (unlock.state.index >= UnlockState.unlocked.index)
                          NeonButton(
                            label: '◈ CIPHER ◈',
                            onPressed: () => context.push('/cipher'),
                            color: NeonTheme.neonPurple,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (kDebugMode)
                    Text(
                      'DEV: ${auth.user?.username ?? "?"} | ${settings.language} | D:${settings.difficulty}',
                      style: const TextStyle(color: Colors.white24, fontSize: 9),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 80; i++) {
      final x = (i * 137.5 + progress * size.width * 0.3) % size.width;
      final y = (i * 97.3 + progress * size.height) % size.height;
      final radius = (i % 3 + 1) * 0.5;
      paint.color = Colors.white.withValues(alpha: 0.2 + (i % 5) * 0.15);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
