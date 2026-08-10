import 'dart:math';

import 'package:flutter/material.dart';

/// Neon Illuminati / matrix third-eye glyph used on operator identity cards.
class MatrixIlluminatiEye extends StatefulWidget {
  const MatrixIlluminatiEye({
    super.key,
    this.size = 120,
    this.revealed = false,
  });

  final double size;

  /// When Darth Cherry is active, the pupil glows hotter.
  final bool revealed;

  @override
  State<MatrixIlluminatiEye> createState() => _MatrixIlluminatiEyeState();
}

class _MatrixIlluminatiEyeState extends State<MatrixIlluminatiEye>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
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
        builder: (context, _) {
          return CustomPaint(
            painter: _CardEyePainter(
              t: _ctrl.value,
              revealed: widget.revealed,
            ),
          );
        },
      ),
    );
  }
}

class _CardEyePainter extends CustomPainter {
  _CardEyePainter({required this.t, required this.revealed});

  final double t;
  final bool revealed;

  static const _palette = [
    Color(0xFF39FF14),
    Color(0xFF00F0FF),
    Color(0xFFFF2D95),
    Color(0xFFFFF200),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final flash = 0.55 + 0.45 * sin(t * pi * 6);
    final accent = revealed ? const Color(0xFFFF0040) : const Color(0xFF39FF14);

    // Soft matrix rain behind the eye
    final paint = Paint()..color = accent.withValues(alpha: 0.12);
    for (var c = 0; c < 8; c++) {
      final x = c * (size.width / 8) + 4;
      for (var r = 0; r < 6; r++) {
        final y = (r * 18.0 + c * 9 + t * size.height) % (size.height + 20);
        canvas.drawRect(Rect.fromLTWH(x, y, 1.5, 8), paint);
      }
    }

    final scale = size.width / 160;
    final tri = Path()
      ..moveTo(cx, cy - 55 * scale)
      ..lineTo(cx - 48 * scale, cy + 34 * scale)
      ..lineTo(cx + 48 * scale, cy + 34 * scale)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: flash),
    );
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.black.withValues(alpha: 0.55),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy - 4 * scale),
        width: 44 * scale,
        height: 28 * scale,
      ),
      Paint()..color = accent.withValues(alpha: 0.25 + 0.2 * flash),
    );
    canvas.drawCircle(
      Offset(cx, cy - 4 * scale),
      11 * scale,
      Paint()
        ..color = (revealed ? const Color(0xFFFF2D95) : const Color(0xFFFF2D95))
            .withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(cx, cy - 4 * scale),
      5.5 * scale,
      Paint()..color = const Color(0xFFFFF200),
    );
    canvas.drawCircle(
      Offset(cx, cy - 4 * scale),
      3 * scale,
      Paint()..color = Colors.black,
    );

    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3 + t * pi;
      final p = Paint()
        ..color = _palette[i % _palette.length].withValues(alpha: 0.4 * flash)
        ..strokeWidth = 1.1;
      canvas.drawLine(
        Offset(cx + cos(a) * 22 * scale, cy - 4 * scale + sin(a) * 22 * scale),
        Offset(cx + cos(a) * 58 * scale, cy - 4 * scale + sin(a) * 58 * scale),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardEyePainter old) =>
      old.t != t || old.revealed != revealed;
}
