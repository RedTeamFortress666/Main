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
    return Text(
      'LEAK SWEEP  ${report.openCount} OPEN  ·  ${report.patchedCount} PATCHED  ·  ${report.residualCount} RESIDUAL',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        color: color,
      ),
    );
  }
}
