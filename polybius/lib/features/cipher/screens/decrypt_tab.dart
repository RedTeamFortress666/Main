import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:polybius/core/crypto/unique_qr.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

class DecryptTab extends ConsumerStatefulWidget {
  const DecryptTab({super.key});

  @override
  ConsumerState<DecryptTab> createState() => _DecryptTabState();
}

class _DecryptTabState extends ConsumerState<DecryptTab> {
  final _assembler = UniqueQrAssembler();
  final _paste = TextEditingController();
  String _output = '';
  String? _status;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  void _open(String payload) {
    final engine = ref.read(cipherEngineProvider);
    final text = engine.decrypt(payload);
    setState(() {
      _output = text;
      _status = text.isEmpty ? 'DECAP FAILED' : 'OPENED';
    });
    ref.read(storageServiceProvider).logAudit(
          'DECRYPT',
          ref.read(authProvider).user?.username ?? 'UNKNOWN',
        );
  }

  void _ingest(String raw) {
    if (UniqueQrCodec.isFrame(raw)) {
      final joined = _assembler.add(raw);
      if (joined == null) {
        setState(() => _status = 'FRAME ${_assembler.seen}');
        return;
      }
      _assembler.reset();
      _open(joined);
      return;
    }
    _open(raw);
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanScreen()),
    );
    if (result != null) _ingest(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('SCAN UNIQUE QR'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _paste,
            maxLines: 3,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: const InputDecoration(
              labelText: 'or paste envelope',
              labelStyle: TextStyle(color: NeonTheme.cherryBright),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _ingest(_paste.text.trim()),
            child: const Text('OPEN'),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _status!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.cherryGold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: NeonTheme.cherryBright),
                color: NeonTheme.cherryGlass,
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty ? '…' : _output,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanScreen extends StatelessWidget {
  const _ScanScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('SCAN DC3', style: TextStyle(fontFamily: 'monospace')),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
