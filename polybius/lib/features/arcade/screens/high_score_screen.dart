import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';
import 'package:polybius/features/arcade/high_score_models.dart';

/// High-score board — players enter their real name; QR pool sync merges
/// peer boards so operators can compete across devices.
class HighScoreScreen extends ConsumerStatefulWidget {
  const HighScoreScreen({super.key});

  @override
  ConsumerState<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends ConsumerState<HighScoreScreen> {
  late final TextEditingController _nameController;
  final _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(playerDisplayNameProvider),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await ref.read(playerDisplayNameProvider.notifier).setName(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NeonTheme.surface,
        content: Text(
          'PLAYER NAME SET — $name',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.neonGreen,
          ),
        ),
      ),
    );
  }

  Future<void> _manualSubmit() async {
    final name = _nameController.text.trim();
    final score = int.tryParse(_scoreController.text.trim()) ?? 0;
    if (name.isEmpty || score <= 0) return;
    await ref.read(highScoresProvider.notifier).submit(name: name, score: score);
    _scoreController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scores = ref.watch(highScoresProvider);
    final rows = scores.isEmpty
        ? const <HighScoreEntry>[]
        : scores.take(10).toList();

    return ArcadeScaffold(
      accent: NeonTheme.neonCyan,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const ArcadeTitle(fontSize: 34, showStrapline: false),
          const SizedBox(height: 16),
          const ArcadeHeading('HIGH SCORES', color: NeonTheme.neonCyan),
          const SizedBox(height: 8),
          const Text(
            'Enter your name. Sync a pool QR with another player to merge boards.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _HeaderCell('RANK')),
              Expanded(flex: 2, child: _HeaderCell('NAME')),
              Expanded(child: _HeaderCell('SCORE', align: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: rows.isEmpty
                ? const Center(
                    child: Text(
                      'NO SCORES YET — PLAY A ROUND',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final entry = rows[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${i + 1}.',
                                style: _rowStyle(NeonTheme.neonCyan),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.name,
                                overflow: TextOverflow.ellipsis,
                                style: _rowStyle(NeonTheme.neonCyan),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${entry.score}',
                                textAlign: TextAlign.right,
                                style: _rowStyle(Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              const Text(
                'YOUR NAME:',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                  letterSpacing: 1,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ArcadeField(
                  controller: _nameController,
                  fontSize: 16,
                  letterSpacing: 1,
                  textColor: NeonTheme.neonCyan,
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 8),
              ArcadeMenuButton(
                label: 'SET',
                color: NeonTheme.neonGreen,
                dense: true,
                onPressed: _saveName,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ArcadeField(
                  controller: _scoreController,
                  fontSize: 14,
                  letterSpacing: 1,
                  textColor: NeonTheme.neonYellow,
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(width: 8),
              ArcadeMenuButton(
                label: 'ADD SCORE',
                color: NeonTheme.neonYellow,
                dense: true,
                onPressed: _manualSubmit,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tip: finish a game to post your score automatically.',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
          const SizedBox(height: 12),
          ArcadeMenuButton(
            label: 'BACK',
            color: NeonTheme.neonPink,
            dense: true,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/menu');
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  TextStyle _rowStyle(Color color) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 16,
        color: color,
        letterSpacing: 1,
      );
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.align = TextAlign.left});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontFamily: 'monospace',
        color: Colors.white54,
        letterSpacing: 2,
        fontSize: 13,
      ),
    );
  }
}
