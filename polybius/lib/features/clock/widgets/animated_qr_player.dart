import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Cycles Polybius-keyboard QR frames so a peer can scan the whole envelope.
class AnimatedQrPlayer extends StatefulWidget {
  const AnimatedQrPlayer({
    super.key,
    required this.frames,
    this.period = const Duration(milliseconds: 220),
    this.size = 220,
  });

  final List<String> frames;
  final Duration period;
  final double size;

  @override
  State<AnimatedQrPlayer> createState() => _AnimatedQrPlayerState();
}

class _AnimatedQrPlayerState extends State<AnimatedQrPlayer> {
  Timer? _tick;
  var _i = 0;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant AnimatedQrPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frames != widget.frames) {
      _i = 0;
      _arm();
    }
  }

  void _arm() {
    _tick?.cancel();
    if (widget.frames.length <= 1) return;
    _tick = Timer.periodic(widget.period, (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % widget.frames.length);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) return const SizedBox.shrink();
    final frame = widget.frames[_i % widget.frames.length];
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(8),
          child: QrImageView(data: frame, size: widget.size),
        ),
        const SizedBox(height: 6),
        Text(
          'PBK ${_i + 1}/${widget.frames.length}',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
