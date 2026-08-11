import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/app_flavor.dart';
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
  bool _scoreSaved = false;

  Timer? _holdTimer;
  bool _holdingGameOver = false;
  bool _glitch = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(playerDisplayNameProvider),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _leaveGame() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/menu');
    }
  }

  Future<void> _saveScore() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _finalScore <= 0 || _scoreSaved) return;
    await ref.read(highScoresProvider.notifier).submit(
          name: name,
          score: _finalScore,
        );
    if (!mounted) return;
    setState(() => _scoreSaved = true);
  }

  void _startGameOverHold() {
    // Previous / V.1 path: hold GAME OVER only when the early-loss error
    // pathway is eligible (level < 3 || kills < 6). PORTAL also allows the
    // settings ritual (diff 11 + Russian) to arm the hold.
    final settings = ref.read(gameSettingsProvider);
    final ritualReady =
        ref.read(unlockProvider.notifier).isPortalRitualReady(settings);
    final earlyLoss = _errorEligible || (_game?.errorPathEligible ?? false);
    final canHold = AppFlavor.isUser
        ? earlyLoss
        : (ritualReady || earlyLoss);
    if (!canHold) return;
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
          // Classic hold-GAME-OVER path: early loss unlocks the ERROR ritual.
          _errorEligible = _game?.errorPathEligible ?? false;
          _showGameOver = true;
          _scoreSaved = false;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = ref.read(playerDisplayNameProvider);
          }
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
                    onPressed: _leaveGame,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hold "GAME OVER" when early-loss eligible (classic pathway).
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
                    shadows: const [
                      Shadow(color: NeonTheme.dangerRed, blurRadius: 16)
                    ],
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
              const SizedBox(height: 18),
              const Text(
                'ENTER YOUR NAME',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonCyan,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonCyan,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'PLAYER NAME',
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: NeonTheme.neonCyan),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: _scoreSaved ? 'SCORE SAVED' : 'SAVE TO HIGH SCORES',
                color: NeonTheme.neonYellow,
                onPressed: _scoreSaved ? null : _saveScore,
              ),
              const SizedBox(height: 8),
              Text(
                AppFlavor.isUser
                    ? 'Sync a pool QR later to share your board with peers.'
                    : 'Pool QR sync merges high-score boards across operators.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeonButton(
                    label: 'QUIT',
                    color: NeonTheme.dangerRed,
                    onPressed: _leaveGame,
                  ),
                  const SizedBox(width: 16),
                  NeonButton(
                    label: 'CONTINUE',
                    color: NeonTheme.neonGreen,
                    onPressed: () {
                      setState(() {
                        _showGameOver = false;
                        _game = null;
                        _scoreSaved = false;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/highscore'),
                child: const Text(
                  'VIEW HIGH SCORES',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
