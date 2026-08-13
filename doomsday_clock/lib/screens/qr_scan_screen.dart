import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/cherry_vault_card.dart';
import '../services/qr_card_codec.dart';
import '../theme/noir_theme.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final card = QrCardCodec.decode(raw);
      if (card == null) continue;
      _handled = true;
      Navigator.of(context).pop<CherryVaultCard>(card);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoirTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: NoirTheme.panel,
        title: const Text('SCAN OPERATOR QR'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(onDetect: _onDetect),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Point at a DARTH CHERRY share QR from another DOØMSDAY CLØCK vault.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: NoirTheme.mist.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
