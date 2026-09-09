import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/net/t3mp_client.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';

class DecryptTab extends ConsumerStatefulWidget {
  const DecryptTab({super.key});

  @override
  ConsumerState<DecryptTab> createState() => _DecryptTabState();
}

class _DecryptTabState extends ConsumerState<DecryptTab> {
  final _inputController = TextEditingController();
  String _output = '';
  String? _fetchError;
  bool _working = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _decrypt() async {
    if (_working) return;
    var input = _inputController.text.trim();
    setState(() {
      _working = true;
      _fetchError = null;
    });
    try {
      if (T3mpClient.isDropUrl(input)) {
        input = (await ref.read(t3mpClientProvider).downloadText(input)).trim();
        if (!mounted) return;
        _inputController.text = input;
        ref.read(storageServiceProvider).logAudit(
              'T3MP_FETCH',
              ref.read(authProvider).user?.username ?? 'UNKNOWN',
              'cipher',
            );
      }
      final engine = ref.read(cipherEngineProvider);
      setState(() => _output = engine.decrypt(input));
      ref.read(storageServiceProvider).logAudit(
            'DECRYPT',
            ref.read(authProvider).user?.username ?? 'UNKNOWN',
          );
    } on T3mpException catch (e) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _fetchError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _output = '';
        _fetchError = 'DECRYPT FAILED';
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
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
              labelText: 'EMOJI CIPHERTEXT OR T3MP URL',
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
            onPressed: _working ? null : _decrypt,
            child: Text(_working ? 'WORKING…' : 'DECRYPT'),
          ),
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
          if (_fetchError != null)
            Text(
              _fetchError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.dangerRed,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}
