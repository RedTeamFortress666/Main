import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';

/// Live view of the three Enigma rotors — step counts and engine status.
class RotorGearSheet extends ConsumerWidget {
  const RotorGearSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(cipherEngineProvider);
    final rotors = engine.rotors;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '⚙ ROTOR GEAR STATUS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonCyan,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ...rotors.map((r) => _RotorCard(rotor: r)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: NeonTheme.neonGreen),
              color: NeonTheme.background,
            ),
            child: Column(
              children: [
                const Text(
                  'ENGINE STATUS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '◈ OPERATIONAL ◈',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen.withValues(alpha: 0.8),
                    fontSize: 14,
                    shadows: const [
                      Shadow(color: NeonTheme.neonGreen, blurRadius: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pool: ${engine.dateKey} | Alphabet: ${Rotor.alphabetSize}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RotorCard extends StatelessWidget {
  const _RotorCard({required this.rotor});

  final dynamic rotor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: NeonTheme.neonPink.withValues(alpha: 0.5)),
        color: NeonTheme.background,
      ),
      child: Row(
        children: [
          Text(
            'ROTOR ${rotor.name}',
            style: const TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonPink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'POS: ${rotor.position}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonCyan,
                  fontSize: 12,
                ),
              ),
              Text(
                'STEPS: ${rotor.stepCount}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              Text(
                'NOTCH: ${rotor.notch}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
