import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _inputController,
            maxLines: 4,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              labelText: 'EMOJI CIPHERTEXT',
              labelStyle: TextStyle(color: NeonTheme.neonPink),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _decrypt, child: const Text('DECRYPT')),
          const SizedBox(height: 16),
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
          if (_output.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _output));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy, color: NeonTheme.neonPink),
              label: const Text('COPY', style: TextStyle(color: NeonTheme.neonPink)),
            ),
        ],
      ),
    );
  }
}
