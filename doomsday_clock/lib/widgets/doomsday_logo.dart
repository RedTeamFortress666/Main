import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/noir_theme.dart';

/// Brand mark: Dalí melting clock + nuclear mushroom cloud trapped in an hourglass.
class DoomsdayLogo extends StatelessWidget {
  const DoomsdayLogo({
    super.key,
    this.size = 120,
    this.showWordmark = true,
  });

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 1.3,
          child: CustomPaint(painter: _DaliDoomsdayPainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          Text(
            'DOØMSDAY CLØCK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              fontSize: size * 0.13,
              color: NoirTheme.matrix,
              shadows: [
                Shadow(
                  color: NoirTheme.matrix.withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
                Shadow(
                  color: NoirTheme.crimson.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DaliDoomsdayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;

    // Soft vignette glow
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.48,
      Paint()
        ..color = NoirTheme.crimson.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    _paintMeltingClock(canvas, size, cx, cy);
    _paintHourglass(canvas, size, cx);
  }

  void _paintMeltingClock(Canvas canvas, Size size, double cx, double cy) {
    final faceR = size.width * 0.38;
    final face = Path()
      ..moveTo(cx - faceR * 0.85, cy - faceR * 0.55)
      ..quadraticBezierTo(
        cx - faceR * 1.05,
        cy,
        cx - faceR * 0.75,
        cy + faceR * 0.75,
      )
      ..quadraticBezierTo(
        cx - faceR * 0.2,
        cy + faceR * 1.15,
        cx + faceR * 0.15,
        cy + faceR * 0.95,
      )
      ..quadraticBezierTo(
        cx + faceR * 0.55,
        cy + faceR * 0.55,
        cx + faceR * 0.9,
        cy + faceR * 0.15,
      )
      ..quadraticBezierTo(
        cx + faceR * 1.05,
        cy - faceR * 0.35,
        cx + faceR * 0.55,
        cy - faceR * 0.75,
      )
      ..quadraticBezierTo(
        cx,
        cy - faceR * 0.95,
        cx - faceR * 0.85,
        cy - faceR * 0.55,
      )
      ..close();

    // Melting drip
    face
      ..moveTo(cx + faceR * 0.05, cy + faceR * 0.9)
      ..quadraticBezierTo(
        cx + faceR * 0.12,
        cy + faceR * 1.35,
        cx - faceR * 0.05,
        cy + faceR * 1.45,
      )
      ..quadraticBezierTo(
        cx - faceR * 0.18,
        cy + faceR * 1.2,
        cx - faceR * 0.08,
        cy + faceR * 0.95,
      );

    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFE8E0D0),
    );
    canvas.drawPath(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.black87,
    );

    // Tick marks
    final tick = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = -pi / 2 + i * (pi / 6);
      final inner = faceR * 0.62;
      final outer = faceR * 0.78;
      final ox = cx + cos(a) * 0.08 * faceR;
      final oy = cy - faceR * 0.08;
      canvas.drawLine(
        Offset(ox + cos(a) * inner, oy + sin(a) * inner),
        Offset(ox + cos(a) * outer, oy + sin(a) * outer),
        tick,
      );
    }

    // Hands ~ two minutes to midnight
    final handPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final hub = Offset(cx, cy - faceR * 0.08);
    // Minute hand near 12
    canvas.drawLine(
      hub,
      Offset(hub.dx - faceR * 0.08, hub.dy - faceR * 0.55),
      handPaint,
    );
    // Hour hand near 11:58
    canvas.drawLine(
      hub,
      Offset(hub.dx - faceR * 0.28, hub.dy - faceR * 0.32),
      handPaint,
    );
    canvas.drawCircle(hub, 2.2, Paint()..color = Colors.black87);
  }

  void _paintHourglass(Canvas canvas, Size size, double cx) {
    final top = size.height * 0.08;
    final mid = size.height * 0.5;
    final bot = size.height * 0.92;
    final glassW = size.width * 0.28;

    // Frame pillars
    final frame = Paint()
      ..color = const Color(0xFFE8E0D0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - glassW - 6, top),
      Offset(cx - glassW - 6, bot),
      frame,
    );
    canvas.drawLine(
      Offset(cx + glassW + 6, top),
      Offset(cx + glassW + 6, bot),
      frame,
    );
    canvas.drawLine(
      Offset(cx - glassW - 10, top),
      Offset(cx + glassW + 10, top),
      frame..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(cx - glassW - 10, bot),
      Offset(cx + glassW + 10, bot),
      frame,
    );

    final glass = Path()
      ..moveTo(cx - glassW, top + 4)
      ..lineTo(cx + glassW, top + 4)
      ..lineTo(cx + glassW * 0.16, mid)
      ..lineTo(cx + glassW, bot - 4)
      ..lineTo(cx - glassW, bot - 4)
      ..lineTo(cx - glassW * 0.16, mid)
      ..close();

    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0A0A0A).withValues(alpha: 0.55),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFE8E0D0).withValues(alpha: 0.85),
    );

    // Red mushroom cloud (upper) flowing through neck
    final cloudY = top + size.height * 0.18;
    final red = Paint()..color = const Color(0xFFC41212);
    final lobes = [
      Offset(cx, cloudY),
      Offset(cx - size.width * 0.11, cloudY + 6),
      Offset(cx + size.width * 0.11, cloudY + 6),
      Offset(cx - size.width * 0.055, cloudY - 8),
      Offset(cx + size.width * 0.055, cloudY - 8),
    ];
    for (final o in lobes) {
      canvas.drawCircle(o, size.width * 0.075, red);
    }

    // Stem through neck
    final stem = Path()
      ..moveTo(cx - size.width * 0.035, cloudY + size.height * 0.08)
      ..lineTo(cx + size.width * 0.035, cloudY + size.height * 0.08)
      ..lineTo(cx + size.width * 0.018, mid + 2)
      ..lineTo(cx - size.width * 0.018, mid + 2)
      ..close();
    canvas.drawPath(stem, red);

    // Lower fallout pile / second bloom
    final pile = Path()
      ..moveTo(cx - glassW * 0.55, bot - 6)
      ..quadraticBezierTo(cx, bot - size.height * 0.14, cx + glassW * 0.55, bot - 6)
      ..close();
    canvas.drawPath(pile, red);
    canvas.drawCircle(
      Offset(cx, bot - size.height * 0.12),
      size.width * 0.07,
      red,
    );

    // Ash flecks
    final rng = Random(7);
    final ash = Paint()..color = const Color(0xFFC41212).withValues(alpha: 0.65);
    for (var i = 0; i < 14; i++) {
      final x = cx + (rng.nextDouble() - 0.5) * glassW * 0.45;
      final y = mid + 4 + rng.nextDouble() * (bot - mid - 20);
      canvas.drawCircle(Offset(x, y), 1.0 + rng.nextDouble(), ash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
