import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/noir_theme.dart';

/// Neon Illuminati eye for operator identity cards.
class IlluminatiEye extends StatefulWidget {
  const IlluminatiEye({super.key, this.size = 88, this.revealed = false});

  final double size;
  final bool revealed;

  @override
  State<IlluminatiEye> createState() => _IlluminatiEyeState();
}

class _IlluminatiEyeState extends State<IlluminatiEye>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _EyePainter(t: _ctrl.value, revealed: widget.revealed),
        ),
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  _EyePainter({required this.t, required this.revealed});

  final double t;
  final bool revealed;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final pulse = 0.55 + 0.45 * sin(t * pi * 5);
    final accent = revealed ? NoirTheme.crimson : NoirTheme.neonCyan;

    final tri = Path()
      ..moveTo(cx, cy - size.height * 0.38)
      ..lineTo(cx - size.width * 0.42, cy + size.height * 0.34)
      ..lineTo(cx + size.width * 0.42, cy + size.height * 0.34)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..color = accent.withValues(alpha: 0.18 + pulse * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.22,
      Paint()
        ..color = accent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.09 * (0.8 + pulse * 0.2),
      Paint()..color = accent.withValues(alpha: revealed ? 1 : 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _EyePainter old) =>
      old.t != t || old.revealed != revealed;
}
