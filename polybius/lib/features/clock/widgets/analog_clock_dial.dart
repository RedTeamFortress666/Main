import 'dart:math';

import 'package:flutter/material.dart';
import 'package:polybius/features/clock/roman24.dart';

/// 24-hour analog dial with Roman hour marks (I–XXIV).
class AnalogClockDial extends StatelessWidget {
  const AnalogClockDial({
    super.key,
    required this.hour,
    required this.minute,
    this.cherry = false,
    this.size = 240,
  });

  final int hour;
  final int minute;
  final bool cherry;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Analog face ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      child: CustomPaint(
        size: Size.square(size),
        painter: _DialPainter(
          hour: hour,
          minute: minute,
          cherry: cherry,
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.hour,
    required this.minute,
    required this.cherry,
  });

  final int hour;
  final int minute;
  final bool cherry;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    final rim = cherry ? const Color(0xFFFF2A4D) : const Color(0xFF00FFFF);
    final hand = cherry ? const Color(0xFFFFC1C8) : const Color(0xFFE8F6FF);
    final face = cherry ? const Color(0xFF1A0008) : const Color(0xFF071018);

    canvas.drawCircle(c, r, Paint()..color = face);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 1; i <= 24; i++) {
      final angle = (i / 24) * 2 * pi - pi / 2;
      final mark = Offset(c.dx + cos(angle) * (r - 18), c.dy + sin(angle) * (r - 18));
      textPainter.text = TextSpan(
        text: Roman24.hours[i - 1],
        style: TextStyle(
          fontSize: i % 2 == 0 ? 9 : 7,
          fontFamily: 'monospace',
          color: rim.withValues(alpha: 0.85),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        mark - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final hourAngle =
        ((hour % 24) + minute / 60) / 24 * 2 * pi - pi / 2;
    final minuteAngle = (minute / 60) * 2 * pi - pi / 2;

    void handLine(double angle, double length, double width) {
      canvas.drawLine(
        c,
        Offset(c.dx + cos(angle) * length, c.dy + sin(angle) * length),
        Paint()
          ..color = hand
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    handLine(hourAngle, r * 0.52, 4);
    handLine(minuteAngle, r * 0.78, 2.4);
    canvas.drawCircle(c, 4, Paint()..color = rim);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.hour != hour ||
      oldDelegate.minute != minute ||
      oldDelegate.cherry != cherry;
}
