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
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return CustomPaint(
          painter: _RainPainter(t: _c.value),
          child: widget.child,
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / 16).floor().clamp(6, 28);
    final rows = (size.height / 18).floor().clamp(10, 50);
    const glyphs = '01アカサタナハマヤラワPOLYBIUSGRØK';
    for (var c = 0; c < cols; c++) {
      final head = ((t * (10 + c % 7) * rows) + c * 5) % (rows + 10);
      for (var r = 0; r < rows; r++) {
        final d = head - r;
        if (d < 0 || d > 10) continue;
        final ch = glyphs[(c * 11 + r + (t * 30).floor()) % glyphs.length];
        final alpha = (1 - d / 10).clamp(0.05, 0.35);
        final tp = TextPainter(
          text: TextSpan(
            text: ch,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: NoirTheme.matrix.withValues(alpha: alpha),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c * 16.0, r * 18.0));
      }
    }
    // vignette
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            NoirTheme.ink.withValues(alpha: 0.75),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => old.t != t;
}

class NeonPanel extends StatelessWidget {
  const NeonPanel({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? NoirTheme.matrix;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NoirTheme.panel.withValues(alpha: 0.88),
        border: Border.all(color: c.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.18), blurRadius: 18),
        ],
      ),
      child: child,
    );
  }
}

double matrixNoise(int seed) => Random(seed).nextDouble();
