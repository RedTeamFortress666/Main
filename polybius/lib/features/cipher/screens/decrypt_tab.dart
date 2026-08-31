import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';

class DecryptTab extends ConsumerStatefulWidget {
  const DecryptTab({super.key});

  @override
  ConsumerState<DecryptTab> createState() => _DecryptTabState();
}

class _DecryptTabState extends ConsumerState<DecryptTab> {
  final _inputController = TextEditingController();
  String _output = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _decrypt() {
    final seed = ref.read(cipherEngineProvider).seed;
    final policy = ref.read(cabinetPolicyProvider);
    final text = _inputController.text;
    final out = policy.autoDensity
        ? CipherEngine.decryptAuto(seed: seed, text: text)
        : CipherEngine(
            seed: seed,
            density: ref.read(glyphDensityProvider),
            stego: false,
          ).decrypt(text);
    setState(() {
      _output = out;
    });
    ref.read(storageServiceProvider).logAudit(
          'DECRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inputController,
            maxLines: 3,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              labelText: 'EMOJI CIPHERTEXT',
              labelStyle: TextStyle(color: NeonTheme.neonPink),
              border: OutlineInputBorder(),
            ),
          ),
          ClipboardRow(
            color: NeonTheme.neonPink,
            getCopyText: () => _inputController.text,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
          const SizedBox(height: 4),
          ElevatedButton(onPressed: _decrypt, child: const Text('DECRYPT')),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: NeonTheme.neonPink),
                color: NeonTheme.surface,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty ? '...' : _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          ClipboardRow(
            color: NeonTheme.neonGreen,
            getCopyText: () => _output,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
        ],
      ),
    );
  }
}
