import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Hybrid engine status. No emoji pool, no seed, no rotor wiring.
class RotorGearSheet extends ConsumerWidget {
  const RotorGearSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(cipherEngineProvider);
    final peer = ref.watch(peerPublicKeyProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '⚙ HYBRID ENGINE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.cherryBright,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _row('ALG', 'ML-KEM-768 + AES-256-GCM'),
          _row('LOCAL', engine.keystore.fingerprint),
          _row(
            'PEER',
            peer == null ? '(self)' : engine.fingerprint,
          ),
          const SizedBox(height: 12),
          const Text(
            'Private keys stay on-device. Each SEAL is a unique envelope.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.cherryGold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
