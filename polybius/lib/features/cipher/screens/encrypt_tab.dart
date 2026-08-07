import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';
import 'package:polybius/features/cipher/veil/ghost_plaintext_field.dart';
import 'package:polybius/features/cipher/veil/veil_eyeball.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

class EncryptTab extends ConsumerStatefulWidget {
  const EncryptTab({super.key});

  @override
  ConsumerState<EncryptTab> createState() => _EncryptTabState();
}

class _EncryptTabState extends ConsumerState<EncryptTab> {
  final _inputController = TextEditingController();
  String _output = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _encrypt() {
    final engine = ref.read(cipherEngineProvider);
    setState(() {
      _output = engine.encrypt(_inputController.text);
    });
    ref.read(storageServiceProvider).logAudit(
          'ENCRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
          '${_inputController.text.length} chars',
        );
  }

  @override
  Widget build(BuildContext context) {
    final veil = ref.watch(veilProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ENCRYPT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const VeilEyeballButton(),
            ],
          ),
          const SizedBox(height: 8),
          GhostPlaintextField(
            controller: _inputController,
            mode: veil.mode,
            label: 'PLAINTEXT',
            labelColor: NeonTheme.neonGreen,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
          ),
          ClipboardRow(
            color: NeonTheme.neonGreen,
            getCopyText: () => _inputController.text,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
          const SizedBox(height: 4),
          ElevatedButton(onPressed: _encrypt, child: const Text('ENCRYPT')),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: NeonTheme.neonCyan),
                color: NeonTheme.surface,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty ? '...' : _output,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          ClipboardRow(
            color: NeonTheme.neonCyan,
            getCopyText: () => _output,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
        ],
      ),
    );
  }
}
