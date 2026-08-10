import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';
import 'package:polybius/features/cipher/veil/veil_eyeball.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

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
    final engine = ref.read(cipherEngineProvider);
    setState(() {
      _output = engine.decrypt(_inputController.text);
    });
    ref.read(storageServiceProvider).logAudit(
          'DECRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
        );
  }

  @override
  Widget build(BuildContext context) {
    final veil = ref.watch(veilProvider);
    // Under matrix veil the recovered plaintext does not appear at all.
    final hidePlain = veil.mode == VeilMode.matrix;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DECRYPT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonPink,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const VeilEyeballButton(),
            ],
          ),
          const SizedBox(height: 8),
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
          ElevatedButton(
            onPressed: _decrypt,
            child: const Text('DECRYPT VIA CURRENT ROTOR SETTINGS'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: hidePlain
                      ? const Color(0xFF00FF66)
                      : NeonTheme.neonPink,
                ),
                color: hidePlain
                    ? const Color(0xFF031A08)
                    : NeonTheme.surface,
              ),
              child: SingleChildScrollView(
                child: hidePlain
                    ? Text(
                        _output.isEmpty
                            ? 'MATRIX VEIL — plaintext withheld'
                            : 'MATRIX VEIL — ${_output.length} chars held (clipboard still works)',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00FF66),
                          fontSize: 13,
                        ),
                      )
                    : SelectableText(
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
