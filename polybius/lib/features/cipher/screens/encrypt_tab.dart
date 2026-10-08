import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/net/t3mp_client.dart';
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
  String? _dropUrl;
  String? _dropError;
  bool _dropping = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _encrypt() {
    final engine = ref.read(cipherEngineProvider);
    setState(() {
      _output = engine.encrypt(_inputController.text);
      _dropUrl = null;
      _dropError = null;
    });
    ref.read(storageServiceProvider).logAudit(
          'ENCRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
          '${_inputController.text.length} chars',
        );
  }

  Future<void> _dropT3mp() async {
    if (_output.isEmpty || _dropping) return;
    setState(() {
      _dropping = true;
      _dropError = null;
    });
    try {
      final url = await ref.read(t3mpClientProvider).uploadText(
            _output,
            filename: 'cipher.txt',
          );
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      setState(() => _dropUrl = url);
      ref.read(storageServiceProvider).logAudit(
            'T3MP_DROP',
            ref.read(authProvider).user?.username ?? 'UNKNOWN',
            'cipher',
          );
    } on T3mpException catch (e) {
      if (!mounted) return;
      setState(() => _dropError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dropError = 'T3MP DROP FAILED');
    } finally {
      if (mounted) setState(() => _dropping = false);
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
            getCopyText: () => _dropUrl ?? _output,
            onPaste: (text) => setState(() => _inputController.text = text),
          ),
          TextButton.icon(
            onPressed: _dropping ? null : _dropT3mp,
            icon: const Icon(
              Icons.link,
              color: NeonTheme.neonYellow,
              size: 18,
            ),
            label: Text(
              _dropping ? 'DROPPING…' : 'T3MP LINK',
              style: const TextStyle(color: NeonTheme.neonYellow),
            ),
          ),
          if (_dropUrl != null)
            SelectableText(
              _dropUrl!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonYellow,
                fontSize: 11,
              ),
            ),
          if (_dropError != null)
            Text(
              _dropError!,
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
