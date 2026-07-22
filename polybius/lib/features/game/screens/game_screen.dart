import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(gameSettingsProvider);

    _game ??= game.PolybiusGame(
      difficulty: settings.difficulty,
      onGameOver: (score) {
        setState(() {
          _finalScore = score;
          _showGameOver = true;
        });
      },
    );

    return Scaffold(
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
          if (_showGameOver)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 36,
                        color: NeonTheme.dangerRed,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SCORE: $_finalScore',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 24,
                        color: NeonTheme.neonGreen,
                      ),
                    ),
                    const SizedBox(height: 32),
                    NeonButton(
                      label: 'CONTINUE',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
