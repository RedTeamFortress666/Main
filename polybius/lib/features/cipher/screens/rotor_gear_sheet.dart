import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';

/// Live view of the three Enigma rotors — step counts and engine status.
class RotorGearSheet extends ConsumerWidget {
  const RotorGearSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(cabinetPolicyProvider);
    final engine = policy.chromeUsesRealSeed
        ? ref.watch(realCipherEngineProvider)
        : ref.watch(cipherEngineProvider);
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
                  'Pool: ${ref.watch(displayPoolIdProvider)} | SLOT ${engine.slot} | ODO ${Rotor.alphabetSize}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).requestOperatorCheckpoint();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              context.go('/pin');
            },
            child: const Text(
              'GEAR CAL — OPERATOR CHECKPOINT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: NeonTheme.neonYellow,
              ),
            ),
          ),
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
                'NOTCH (FLAVOUR): ${rotor.notch}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
