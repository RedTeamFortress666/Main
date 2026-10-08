import 'dart:math';

import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Animated 1981 cabinet glass: starfield, hex mesh, optional Cherry petals.
class CabinetAtmosphere extends StatefulWidget {
  const CabinetAtmosphere({
    super.key,
    this.cherry = false,
    this.child,
  });

  final bool cherry;
  final Widget? child;

  @override
  State<CabinetAtmosphere> createState() => _CabinetAtmosphereState();
}

class _CabinetAtmosphereState extends State<CabinetAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  late final List<_Star> _stars;
  late final List<_Petal> _petals;
  final _rng = Random(1981);

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _stars = List<_Star>.generate(48, (_) => _Star(_rng));
    _petals = List<_Petal>.generate(18, (_) => _Petal(_rng));
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.15,
                  colors: widget.cherry
                      ? const [
                          Color(0xFF3A0014),
                          Color(0xFF120008),
                          Color(0xFF050002),
                        ]
                      : const [
                          Color(0xFF1A0533),
                          Color(0xFF0D0221),
                          Color(0xFF05010C),
                        ],
                ),
              ),
            ),
            CustomPaint(
              painter: _AtmospherePainter(
                t: _tick.value,
                stars: _stars,
                petals: _petals,
                cherry: widget.cherry,
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _Star {
  _Star(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        phase = rng.nextDouble(),
        size = 0.6 + rng.nextDouble() * 1.6;

  final double x;
  final double y;
  final double phase;
  final double size;
}

class _Petal {
  _Petal(Random rng)
      : x = rng.nextDouble(),
        y0 = rng.nextDouble(),
        drift = rng.nextDouble() * 0.12,
        size = 3 + rng.nextDouble() * 5,
        spin = rng.nextDouble();

  final double x;
  final double y0;
  final double drift;
  final double size;
  final double spin;
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter({
    required this.t,
    required this.stars,
    required this.petals,
    required this.cherry,
  });

  final double t;
  final List<_Star> stars;
  final List<_Petal> petals;
  final bool cherry;

  @override
  void paint(Canvas canvas, Size size) {
    _hex(canvas, size);
    _drawStars(canvas, size);
    if (cherry) _drawPetals(canvas, size);
    _bloom(canvas, size);
  }

  void _hex(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (cherry ? NeonTheme.dangerRed : NeonTheme.neonCyan)
          .withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const r = 22.0;
    final h = r * sqrt(3);
    for (var row = 0; row < size.height / h + 2; row++) {
      for (var col = 0; col < size.width / (r * 1.5) + 2; col++) {
        final cx = col * r * 1.5;
        final cy = row * h + (col.isOdd ? h / 2 : 0);
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3;
          final p = Offset(cx + r * cos(a), cy + r * sin(a));
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in stars) {
      final twinkle = 0.25 + 0.75 * (0.5 + 0.5 * sin(2 * pi * (t + s.phase)));
      paint.color = (cherry ? NeonTheme.dangerRed : NeonTheme.neonCyan)
          .withValues(alpha: 0.15 + 0.55 * twinkle);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        paint,
      );
    }
  }

  void _drawPetals(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xCCFF1A4A);
    for (final p in petals) {
      final y = ((p.y0 + t * 0.55) % 1.0) * size.height;
      final x = (p.x + sin(2 * pi * (t + p.spin)) * p.drift) * size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(2 * pi * (p.spin + t));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.6), paint);
      canvas.restore();
    }
  }

  void _bloom(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          (cherry ? NeonTheme.dangerRed : NeonTheme.neonPink)
              .withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.18),
          radius: size.width * 0.55,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.18),
      size.width * 0.55,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.cherry != cherry;
}
