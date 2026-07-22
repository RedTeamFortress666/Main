import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

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
            maxLines: 4,
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'PLAINTEXT',
              labelStyle: TextStyle(color: NeonTheme.neonGreen),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _encrypt, child: const Text('ENCRYPT')),
          const SizedBox(height: 16),
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
          if (_output.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _output));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, color: NeonTheme.neonCyan),
              label: const Text('COPY', style: TextStyle(color: NeonTheme.neonCyan)),
            ),
        ],
      ),
    );
  }
}
