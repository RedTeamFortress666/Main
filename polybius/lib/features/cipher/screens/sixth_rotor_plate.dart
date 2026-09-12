import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Flavour plate for the physical-paper addendum.
///
/// Not wired into the odometer. Does not encipher. Holds the
/// **6th rotor LLÇ 2026*** heading and the Wu-Tang smallprint from
/// `LEGAL/PHYSICAL_PAPER.md`.
class SixthRotorPlate extends StatelessWidget {
  const SixthRotorPlate({super.key});

  static const heading = '6th rotor LLÇ 2026*';
  static const smallprint = "wutang clan ain't nuthin' 2 fuq with";

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('sixth-rotor-llç-2026'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        color: NeonTheme.background,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'FLAVOUR · NOT IN THE ODOMETER · PA+',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white24,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            smallprint,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white38,
              fontSize: 8,
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
