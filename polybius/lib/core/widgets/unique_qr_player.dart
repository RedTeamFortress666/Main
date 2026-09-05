import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:polybius/core/crypto/unique_qr.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Plays unique DC3 frames. Each [payload] split gets a fresh sid.
class UniqueQrPlayer extends StatefulWidget {
  const UniqueQrPlayer({super.key, required this.payload, this.size = 200});

  final String payload;
  final double size;

  @override
  State<UniqueQrPlayer> createState() => _UniqueQrPlayerState();
}

class _UniqueQrPlayerState extends State<UniqueQrPlayer> {
  late List<String> _frames;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _frames = UniqueQrCodec.split(widget.payload);
    _timer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      if (!mounted || _frames.isEmpty) return;
      setState(() => _index = (_index + 1) % _frames.length);
    });
  }

  @override
  void didUpdateWidget(covariant UniqueQrPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload != widget.payload) {
      _frames = UniqueQrCodec.split(widget.payload);
      _index = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frames[_index % _frames.length];
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: QrImageView(
            data: frame,
            version: QrVersions.auto,
            size: widget.size,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'UNIQUE QR  ${_index + 1}/${_frames.length}',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.cherryGold,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
