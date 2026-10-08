import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/noir_theme.dart';

/// Brand mark: mushroom cloud trapped inside an hourglass.
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
          height: size * 1.25,
          child: CustomPaint(painter: _MushroomHourglassPainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 10),
          Text(
            'DOOMSDAY CLOCK 2.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontSize: size * 0.14,
              color: NoirTheme.matrix,
              shadows: [
                Shadow(
                  color: NoirTheme.matrix.withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
                Shadow(
                  color: NoirTheme.pink.withValues(alpha: 0.35),
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

class _MushroomHourglassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = size.height * 0.06;
    final mid = size.height * 0.5;
    final bot = size.height * 0.94;
    final glassW = size.width * 0.42;

    // Outer glow
    final glow = Paint()
      ..color = NoirTheme.matrix.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - glassW - 6, top - 4, cx + glassW + 6, bot + 4),
        const Radius.circular(8),
      ),
      glow,
    );

    // Hourglass silhouette (two triangles meeting at neck)
    final glass = Path()
      ..moveTo(cx - glassW, top)
      ..lineTo(cx + glassW, top)
      ..lineTo(cx + glassW * 0.18, mid)
      ..lineTo(cx + glassW, bot)
      ..lineTo(cx - glassW, bot)
      ..lineTo(cx - glassW * 0.18, mid)
      ..close();

    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF04140C).withValues(alpha: 0.92),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = NoirTheme.matrix,
    );

    // Caps
    final capPaint = Paint()
      ..color = NoirTheme.pink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - glassW - 4, top), Offset(cx + glassW + 4, top), capPaint);
    canvas.drawLine(Offset(cx - glassW - 4, bot), Offset(cx + glassW + 4, bot), capPaint);

    // Mushroom cloud in upper chamber
    final stemTop = mid - size.height * 0.08;
    final stem = Path()
      ..moveTo(cx - size.width * 0.05, mid - 2)
      ..quadraticBezierTo(cx, stemTop + 10, cx + size.width * 0.05, mid - 2)
      ..close();
    canvas.drawPath(
      stem,
      Paint()..color = NoirTheme.amber.withValues(alpha: 0.85),
    );

    // Cap lobes
    final cloudY = top + size.height * 0.22;
    final lobes = [
      Offset(cx, cloudY),
      Offset(cx - size.width * 0.16, cloudY + 8),
      Offset(cx + size.width * 0.16, cloudY + 8),
      Offset(cx - size.width * 0.08, cloudY - 10),
      Offset(cx + size.width * 0.08, cloudY - 10),
    ];
    for (final o in lobes) {
      canvas.drawCircle(
        o,
        size.width * 0.11,
        Paint()..color = NoirTheme.crimson.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        o.translate(0, -2),
        size.width * 0.07,
        Paint()..color = NoirTheme.yellow.withValues(alpha: 0.55),
      );
    }
    // Stem connection into cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, stemTop + 6),
          width: size.width * 0.1,
          height: size.height * 0.12,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = NoirTheme.orange,
    );

    // Falling sand / ash in lower chamber
    final rng = Random(3);
    final ash = Paint()..color = NoirTheme.matrix.withValues(alpha: 0.55);
    for (var i = 0; i < 18; i++) {
      final x = cx + (rng.nextDouble() - 0.5) * glassW * 0.7;
      final y = mid + 8 + rng.nextDouble() * (bot - mid - 16);
      canvas.drawCircle(Offset(x, y), 1.2 + rng.nextDouble(), ash);
    }

    // Pile at bottom
    final pile = Path()
      ..moveTo(cx - glassW * 0.55, bot - 2)
      ..quadraticBezierTo(cx, bot - size.height * 0.12, cx + glassW * 0.55, bot - 2)
      ..close();
    canvas.drawPath(
      pile,
      Paint()..color = NoirTheme.amber.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
