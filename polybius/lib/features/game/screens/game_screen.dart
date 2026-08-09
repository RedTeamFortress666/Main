import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';
import 'package:polybius/features/game/polybius_game.dart' as game;

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  game.PolybiusGame? _game;
  bool _showGameOver = false;
  int _finalScore = 0;
  bool _errorEligible = false;

  Timer? _holdTimer;
  bool _holdingGameOver = false;
  bool _glitch = false;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startGameOverHold() {
    if (!_errorEligible) return;
    setState(() => _holdingGameOver = true);
    _holdTimer = Timer(
      const Duration(milliseconds: AppConstants.gameOverHoldMs),
      () {
        if (!_holdingGameOver) return;
        setState(() {
          _holdingGameOver = false;
          _glitch = true;
        });
        Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted) {
            setState(() => _glitch = false);
            context.push('/error');
          }
        });
      },
    );
  }

  void _endGameOverHold() {
    setState(() => _holdingGameOver = false);
    _holdTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(gameSettingsProvider);

    _game ??= game.PolybiusGame(
      difficulty: settings.difficulty,
      onGameOver: (score) {
        setState(() {
          _finalScore = score;
          _errorEligible = _game?.errorPathEligible ?? false;
          _showGameOver = true;
        });
        // Stop the arena under the overlay so GAME OVER doesn't look frozen
        // while enemies keep ticking.
        _game?.pauseEngine();
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(game: _game!),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: NeonTheme.neonCyan),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
          if (_showGameOver) _gameOverOverlay(),
        ],
      ),
    );
  }

  Widget _gameOverOverlay() {
    return Container(
      color: _glitch
          ? NeonTheme.neonPurple.withValues(alpha: 0.3)
          : Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hold "GAME OVER" for 6 seconds (when eligible) to reach the
            // hidden dev/admin ERROR report screen.
            GestureDetector(
              onLongPressStart: (_) => _startGameOverHold(),
              onLongPressEnd: (_) => _endGameOverHold(),
              onLongPressCancel: _endGameOverHold,
              child: Text(
                'GAME OVER',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 40,
                  letterSpacing: 4,
                  color: _holdingGameOver
                      ? NeonTheme.neonPurple
                      : NeonTheme.dangerRed,
                  shadows: const [Shadow(color: NeonTheme.dangerRed, blurRadius: 16)],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'would you like to restart?',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SCORE: $_finalScore',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 20,
                color: NeonTheme.neonGreen,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeonButton(
                  label: 'QUIT',
                  color: NeonTheme.dangerRed,
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 16),
                NeonButton(
                  label: 'CONTINUE',
                  color: NeonTheme.neonGreen,
                  onPressed: () {
                    setState(() {
                      _showGameOver = false;
                      _game = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
