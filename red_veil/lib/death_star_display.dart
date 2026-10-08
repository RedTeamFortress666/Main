import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Visual state of the Death Star on the DARTH CHERRY home screen.
enum DeathStarLook {
  /// Filter off — solid station firing a green superlaser.
  idle,

  /// Filter on — green hologram.
  filterOn,

  /// Matrix mode signalled — red hologram.
  matrix,
}

/// Animated Death Star: plain + green beam when idle; green/red hologram when lit.
class DeathStarDisplay extends StatefulWidget {
  const DeathStarDisplay({
    super.key,
    required this.look,
    this.size = 180,
  });

  final DeathStarLook look;
  final double size;

  @override
  State<DeathStarDisplay> createState() => _DeathStarDisplayState();
}

class _DeathStarDisplayState extends State<DeathStarDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _DeathStarPainter(
          look: widget.look,
          t: _pulse.value,
        ),
      ),
    );
  }
}

class _DeathStarPainter extends CustomPainter {
  _DeathStarPainter({required this.look, required this.t});

  final DeathStarLook look;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.48, size.height * 0.52);
    final r = size.shortestSide * 0.38;

    switch (look) {
      case DeathStarLook.idle:
        _paintSolid(canvas, c, r);
        _paintBeam(canvas, c, r, const Color(0xFF00FF66));
      case DeathStarLook.filterOn:
        _paintHologram(canvas, c, r, const Color(0xFF00FF66), t);
      case DeathStarLook.matrix:
        _paintHologram(canvas, c, r, const Color(0xFFFF2A2A), t);
    }
  }

  void _paintSolid(Canvas canvas, Offset c, double r) {
    // Plain matte sphere (no hologram glow).
    final body = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFF6A6A6A),
          Color(0xFF3A3A3A),
          Color(0xFF1A1A1A),
        ],
        stops: const [0.2, 0.65, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, body);

    final trench = Paint()
      ..color = const Color(0xFF0D0D0D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.045;
    canvas.drawLine(
      Offset(c.dx - r * 0.95, c.dy),
      Offset(c.dx + r * 0.95, c.dy),
      trench,
    );

    // Latitude lines
    final line = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final yFrac in [-0.55, -0.3, 0.3, 0.55]) {
      final y = c.dy + r * yFrac;
      final half = math.sqrt(math.max(0.0, r * r - (r * yFrac) * (r * yFrac)));
      canvas.drawLine(Offset(c.dx - half, y), Offset(c.dx + half, y), line);
    }

    _paintDish(canvas, c, r, fill: const Color(0xFF4A4A4A), rim: const Color(0xFF222222));
  }

  void _paintHologram(
    Canvas canvas,
    Offset c,
    double r,
    Color accent,
    double t,
  ) {
    // Soft bloom
    canvas.drawCircle(
      c,
      r * (1.25 + 0.05 * t),
      Paint()..color = accent.withValues(alpha: 0.12 + 0.06 * t),
    );

    final body = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: 0.55),
          accent.withValues(alpha: 0.22),
          accent.withValues(alpha: 0.05),
        ],
        stops: const [0.15, 0.7, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, body);

    final outline = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(c, r, outline);

    // Scan / grid lines
    final grid = Paint()
      ..color = accent.withValues(alpha: 0.35 + 0.2 * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(c.dx - r * 0.92, c.dy),
      Offset(c.dx + r * 0.92, c.dy),
      grid..strokeWidth = r * 0.04,
    );
    for (final yFrac in [-0.6, -0.35, -0.15, 0.15, 0.35, 0.6]) {
      final y = c.dy + r * yFrac;
      final half = math.sqrt(math.max(0.0, r * r - (r * yFrac) * (r * yFrac)));
      canvas.drawLine(
        Offset(c.dx - half, y),
        Offset(c.dx + half, y),
        Paint()
          ..color = accent.withValues(alpha: 0.25)
          ..strokeWidth = 0.8,
      );
    }
    // Speckle / hologram dots
    final rng = math.Random(42);
    final speck = Paint()..color = accent.withValues(alpha: 0.45);
    for (var i = 0; i < 48; i++) {
      final a = rng.nextDouble() * math.pi * 2;
      final d = rng.nextDouble() * r * 0.9;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * d, c.dy + math.sin(a) * d),
        0.8 + rng.nextDouble(),
        speck,
      );
    }

    _paintDish(
      canvas,
      c,
      r,
      fill: accent.withValues(alpha: 0.35),
      rim: accent.withValues(alpha: 0.9),
    );
  }

  void _paintDish(
    Canvas canvas,
    Offset c,
    double r, {
    required Color fill,
    required Color rim,
  }) {
    // Superlaser dish in upper-right quadrant.
    final dishC = Offset(c.dx + r * 0.32, c.dy - r * 0.38);
    final dishR = r * 0.28;
    canvas.drawCircle(dishC, dishR, Paint()..color = fill);
    canvas.drawCircle(
      dishC,
      dishR,
      Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      dishC,
      dishR * 0.35,
      Paint()..color = rim.withValues(alpha: 0.5),
    );
  }

  void _paintBeam(Canvas canvas, Offset c, double r, Color color) {
    final dishC = Offset(c.dx + r * 0.32, c.dy - r * 0.38);
    // Beam shoots up-right from the dish.
    final dir = Offset(0.55, -0.85);
    final len = r * (2.2 + 0.35 * t);
    final end = dishC + dir * len;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.2 + 0.15 * t)
      ..strokeWidth = 10 + 4 * t
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(dishC, end, glow);

    final core = Paint()
      ..color = color.withValues(alpha: 0.85 + 0.15 * t)
      ..strokeWidth = 2.5 + t
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(dishC, end, core);

    // Tip flare
    canvas.drawCircle(
      end,
      3 + 2 * t,
      Paint()..color = color.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _DeathStarPainter old) =>
      old.look != look || old.t != t;
}
