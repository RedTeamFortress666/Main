import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/noir_theme.dart';

class MatrixRainBackground extends StatefulWidget {
  const MatrixRainBackground({super.key, required this.child});

  final Widget child;

  @override
  State<MatrixRainBackground> createState() => _MatrixRainBackgroundState();
}

class _MatrixRainBackgroundState extends State<MatrixRainBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0014), Color(0xFF12002A), Color(0xFF001018)],
            ),
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _RainPainter(t: _c.value),
            ),
          ),
        ),
        CustomPaint(painter: _ScanlinePainter()),
        widget.child,
      ],
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / 14).floor().clamp(8, 32);
    final rows = (size.height / 16).floor().clamp(12, 55);
    const glyphs = '01アカØGRØKCHERRY5NOV';
    for (var c = 0; c < cols; c++) {
      final head = ((t * (8 + c % 5) * rows) + c * 4) % (rows + 8);
      for (var r = 0; r < rows; r++) {
        final d = head - r;
        if (d < 0 || d > 8) continue;
        final ch = glyphs[(c * 7 + r + (t * 24).floor()) % glyphs.length];
        final alpha = (1 - d / 8).clamp(0.04, 0.28);
        final color = c.isEven ? NoirTheme.neonCyan : NoirTheme.neonMagenta;
        final tp = TextPainter(
          text: TextSpan(
            text: ch,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: color.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c * 14.0, r * 16.0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => old.t != t;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeonPanel extends StatelessWidget {
  const NeonPanel({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? NoirTheme.neonCyan;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NoirTheme.panel.withValues(alpha: 0.92),
        border: Border(
          left: BorderSide(color: c, width: 2),
          top: BorderSide(color: c.withValues(alpha: 0.35)),
          right: BorderSide(color: c.withValues(alpha: 0.2)),
          bottom: BorderSide(color: c.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.15), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }
}

double matrixNoise(int seed) => Random(seed).nextDouble();
