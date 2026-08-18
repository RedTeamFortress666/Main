import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/operator_card.dart';
import '../services/qr_card_codec.dart';
import '../theme/noir_theme.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;
  String? _error;

  void _accept(String raw) {
    if (_handled) return;
    final card = QrCardCodec.decode(raw);
    if (card == null) {
      setState(() => _error = 'Could not read that code.');
      return;
    }
    _handled = true;
    Navigator.of(context).pop<OperatorCard>(card);
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      _accept(raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoirTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: NoirTheme.panel,
        title: const Text('Scan card'),
      ),
      body: Column(
        children: [
          Expanded(child: MobileScanner(onDetect: _onDetect)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: NoirTheme.crimson),
                    ),
                  ),
                const Text(
                  'Point the camera at a PØLYBĪUS operator card, or paste a code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: NoirTheme.chrome, fontSize: 12),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    final pasted = await showDialog<String>(
                      context: context,
                      builder: (context) => const _PasteCodeDialog(),
                    );
                    if (pasted != null) _accept(pasted);
                  },
                  child: const Text('Paste code'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteCodeDialog extends StatefulWidget {
  const _PasteCodeDialog();

  @override
  State<_PasteCodeDialog> createState() => _PasteCodeDialogState();
}

class _PasteCodeDialogState extends State<_PasteCodeDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NoirTheme.panel,
      title: const Text('Paste code'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Card code',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
