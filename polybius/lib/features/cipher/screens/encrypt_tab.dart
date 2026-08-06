import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inputController,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'PLAINTEXT',
              labelStyle: TextStyle(color: NeonTheme.neonGreen),
              border: OutlineInputBorder(),
            ),
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
