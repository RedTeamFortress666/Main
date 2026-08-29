import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';

/// High-score board (cosmetic arcade layer), matching the design mockup.
class HighScoreScreen extends ConsumerStatefulWidget {
  const HighScoreScreen({super.key});

  @override
  ConsumerState<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends ConsumerState<HighScoreScreen> {
  static const _rows = <(String, String, String)>[
    ('1.', '', '9999999'),
    ('2.', 'AAA', '8899889'),
    ('3.', 'BBB', '8867788'),
    ('4.', 'DDC', '666555'),
    ('6.', 'EEF', '4589444'),
    ('7.', 'FEF', '222444'),
    ('9.', 'HI', '111000'),
    ('10.', 'JJJ', '000000'),
  ];

  final List<TextEditingController> _initials =
      List.generate(3, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _initials) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cover = ref.watch(duressProvider);
    final identity = cover.active ? cover.coverInitials : 'YOU';
    return ArcadeScaffold(
      accent: NeonTheme.neonCyan,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const ArcadeTitle(fontSize: 34, showStrapline: false),
          const SizedBox(height: 16),
          const ArcadeHeading('HIGH SCORES', color: NeonTheme.neonCyan),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: _HeaderCell('RANK')),
              Expanded(child: _HeaderCell('NAME')),
              Expanded(child: _HeaderCell('SCORE', align: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, i) {
                final (rank, name, score) = _rows[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(rank, style: _rowStyle(NeonTheme.neonCyan)),
                      ),
                      Expanded(
                        child: Text(name, style: _rowStyle(NeonTheme.neonCyan)),
                      ),
                      Expanded(
                        child: Text(
                          score,
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
              Text(
                'ENTER INITIALS: $identity',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 10),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 34,
                    child: ArcadeField(
                      controller: _initials[i],
                      fontSize: 18,
                      letterSpacing: 0,
                      textColor: NeonTheme.neonCyan,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ArcadeMenuButton(
            label: 'BACK',
            color: NeonTheme.neonPink,
            dense: true,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  TextStyle _rowStyle(Color color) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 18,
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
