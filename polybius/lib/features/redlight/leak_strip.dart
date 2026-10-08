import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/leak_detector.dart';

/// Compact Darth Cherry leak-detector readout.
class LeakStrip extends StatelessWidget {
  const LeakStrip({super.key, required this.report});

  final LeakReport report;

  @override
  Widget build(BuildContext context) {
    final color = report.openCount > 0
        ? NeonTheme.dangerRed
        : report.residualCount > 0
            ? NeonTheme.neonYellow
            : NeonTheme.neonGreen;
    return Column(
      children: [
        Text(
          'LEAK SWEEP  ${report.openCount} OPEN  ·  ${report.patchedCount} PATCHED  ·  ${report.residualCount} RESIDUAL',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 0.4,
            color: color,
            shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _seg(report.patchedCount, NeonTheme.neonGreen),
            _seg(report.residualCount, NeonTheme.neonYellow),
            _seg(report.openCount, NeonTheme.dangerRed),
          ],
        ),
      ],
    );
  }

  Widget _seg(int count, Color color) {
    if (count <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: count,
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          boxShadow: [BoxShadow(color: color, blurRadius: 6)],
        ),
      ),
    );
  }
}
