import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

/// Live view of the three Enigma rotors — step counts, engine status,
/// decrypt-via-current-rotor, and pointer to Bluetooth rotor share.
class RotorGearSheet extends ConsumerStatefulWidget {
  const RotorGearSheet({super.key});

  @override
  ConsumerState<RotorGearSheet> createState() => _RotorGearSheetState();
}

class _RotorGearSheetState extends ConsumerState<RotorGearSheet> {
  final _cipherController = TextEditingController();
  String _plain = '';

  @override
  void dispose() {
    _cipherController.dispose();
    super.dispose();
  }

  void _decryptViaCurrentRotor() {
    final engine = ref.read(cipherEngineProvider);
    final out = engine.decrypt(_cipherController.text);
    final veil = ref.read(veilProvider);
    setState(() {
      _plain = veil.mode == VeilMode.matrix
          ? 'MATRIX VEIL — ${out.length} chars held'
          : out;
    });
    ref.read(storageServiceProvider).logAudit(
          'ROTOR_DECRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
        );
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(cipherEngineProvider);
    final rotors = engine.rotors;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                    'Pool: ${engine.poolId} | Alphabet: ${Rotor.alphabetSize}',
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DECRYPT VIA CURRENT ROTOR',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonPink,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cipherController,
              maxLines: 2,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Emoji ciphertext',
                labelStyle: TextStyle(color: NeonTheme.neonPink, fontSize: 12),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _decryptViaCurrentRotor,
              icon: const Icon(Icons.lock_open),
              label: const Text('DECRYPT VIA CURRENT ROTOR SETTINGS'),
              style: ElevatedButton.styleFrom(
                foregroundColor: NeonTheme.neonCyan,
                side: const BorderSide(color: NeonTheme.neonCyan, width: 2),
              ),
            ),
            if (_plain.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                _plain,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonGreen,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'To share this pool + rotor config over Bluetooth, open CONNECT → pick a peer → SHARE ROTOR / POOL. Both devices must confirm the onscreen code.',
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
