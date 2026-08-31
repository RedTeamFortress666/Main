import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/leak_strip.dart';

/// Darth Cherry lockup + leak sweep. House lights vs phosphor lamp.
class CherryBanner extends StatelessWidget {
  const CherryBanner({
    super.key,
    required this.lampOn,
    required this.report,
  });

  final bool lampOn;
  final LeakReport report;

  @override
  Widget build(BuildContext context) {
    final accent = lampOn ? NeonTheme.dangerRed : const Color(0xFFFF6B8A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A000C),
            NeonTheme.surface,
            const Color(0xFF2A000C),
          ],
        ),
        border: Border.all(color: accent, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: lampOn ? 0.55 : 0.28),
            blurRadius: lampOn ? 18 : 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'DΛRTH  CHERRY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              letterSpacing: 5,
              fontWeight: FontWeight.bold,
              color: accent,
              shadows: [
                Shadow(color: accent, blurRadius: lampOn ? 16 : 8),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lampOn ? 'PHOSPHOR MAP LIVE' : 'HOUSE LIGHTS — LAMP STANDBY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              letterSpacing: 2,
              color: lampOn ? NeonTheme.dangerRed : Colors.white54,
            ),
          ),
          const SizedBox(height: 6),
          LeakStrip(report: report),
        ],
      ),
    );
  }
}
