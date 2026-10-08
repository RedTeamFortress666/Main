import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:polybius/features/clock/animated_qr_codec.dart';
import 'package:polybius/features/clock/keyboard_qr_cipher.dart';

/// Assembles a PBK1 stream and opens it with the desk session key.
class KeyboardQrScanScreen extends StatefulWidget {
  const KeyboardQrScanScreen({super.key, required this.sessionKey});

  final String sessionKey;

  @override
  State<KeyboardQrScanScreen> createState() => _KeyboardQrScanScreenState();
}

class _KeyboardQrScanScreenState extends State<KeyboardQrScanScreen> {
  late final KeyboardQrAssembler _assembler;
  var _status = 'AIM AT KEYBOARD QR';
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _assembler = KeyboardQrAssembler(
      expectedSid: AnimatedQrCodec.sessionIdForKey(widget.sessionKey),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;
    final envelope = _assembler.add(value);
    if (envelope == null) {
      if (AnimatedQrCodec.isKeyboardFrame(value) && mounted) {
        setState(() => _status = 'FRAMES ${_assembler.seen}');
      }
      return;
    }
    _busy = true;
    final bytes = KeyboardQrCipher.open(widget.sessionKey, envelope);
    if (bytes == null) {
      _assembler.reset();
      _busy = false;
      if (mounted) {
        setState(() => _status = 'WRONG KEY OR DAMAGED SQUARE');
      }
      return;
    }
    final dump = ScreenDump.tryParse(bytes);
    Navigator.of(context).pop(dump ?? utf8.decode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'SCAN KEYBOARD',
          style: TextStyle(fontFamily: 'monospace'),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFFFC1C8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
