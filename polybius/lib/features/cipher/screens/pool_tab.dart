import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Identity pane — Kyber fingerprint only. No pool, no seed, no glyphs.
class PoolTab extends ConsumerWidget {
  const PoolTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(cipherEngineProvider);
    final peer = ref.watch(peerPublicKeyProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DARTH CHERRY v3',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.cherryBright,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'LOCAL  ${engine.keystore.fingerprint}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.cherryGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              peer == null
                  ? 'PEER   (self)'
                  : 'PEER   ${engine.fingerprint}',
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ML-KEM-768 + AES-256-GCM\nprivate keys stay on-device',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
