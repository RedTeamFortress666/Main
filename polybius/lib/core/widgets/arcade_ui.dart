import 'dart:math';

import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Shared neon-cyberpunk UI kit used across the arcade screens.
///
/// Provides the recurring visual language from the design mockups: a magenta
/// outer frame with cyan corner brackets, faint radiating vector lines, a
/// hazard-stripe footer bar and the Sinneslöschen copyright line.

const String _copyright = '© 1981 SINNESLÖSCHEN CORP';
const String _rights = 'ALL RIGHTS RESERVED';

/// Full-screen arcade frame wrapper. Wrap any screen body in this to get the
/// consistent neon border, radiating background and footer.
class ArcadeScaffold extends StatelessWidget {
  const ArcadeScaffold({
    super.key,
    required this.child,
    this.showFooter = true,
    this.accent = NeonTheme.neonPink,
  });

  final Widget child;
  final bool showFooter;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _VectorField()),
          Positioned.fill(
            child: CustomPaint(painter: _FramePainter(accent: accent)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
              child: Column(
                children: [
                  Expanded(child: child),
                  if (showFooter) const _ArcadeFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The PØLYBĪUS wordmark + "ARCADE SYSTEM" strapline.
class ArcadeTitle extends StatelessWidget {
  const ArcadeTitle({
    super.key,
    this.color = NeonTheme.neonPink,
    this.fontSize = 44,
    this.showStrapline = true,
  });

  final Color color;
  final double fontSize;
  final bool showStrapline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'PØLYBĪUS',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 8,
            shadows: [
              Shadow(color: color, blurRadius: 18),
              const Shadow(color: NeonTheme.neonCyan, blurRadius: 34),
            ],
          ),
        ),
        if (showStrapline) ...[
          const SizedBox(height: 10),
          const Text(
            '── ARCADE SYSTEM ──',
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonCyan,
              letterSpacing: 6,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

/// Large outlined neon menu button (START GAME / LOAD GAME / etc.).
class ArcadeMenuButton extends StatefulWidget {
  const ArcadeMenuButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
    this.dense = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool dense;

  @override
  State<ArcadeMenuButton> createState() => _ArcadeMenuButtonState();
}

class _ArcadeMenuButtonState extends State<ArcadeMenuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : Colors.white24;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: widget.dense ? 12 : 18),
          decoration: BoxDecoration(
            color: color.withValues(alpha: _down ? 0.16 : 0.04),
            border: Border.all(color: color, width: _down ? 2.5 : 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _down ? 0.6 : 0.28),
                blurRadius: _down ? 20 : 10,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: widget.dense ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 4,
              shadows: [Shadow(color: color, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neon-bordered text field matching the mockups.
class ArcadeField extends StatelessWidget {
  const ArcadeField({
    super.key,
    required this.controller,
    this.hint,
    this.color = NeonTheme.neonCyan,
    this.textColor = NeonTheme.neonYellow,
    this.obscure = false,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.fontSize = 24,
    this.letterSpacing = 6,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? hint;
  final Color color;
  final Color textColor;
  final bool obscure;
  final TextAlign textAlign;
  final int maxLines;
  final double fontSize;
  final double letterSpacing;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textAlign: textAlign,
        maxLines: maxLines,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          color: textColor,
          letterSpacing: letterSpacing,
          shadows: [Shadow(color: textColor, blurRadius: 6)],
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize,
            color: textColor.withValues(alpha: 0.3),
            letterSpacing: letterSpacing,
          ),
        ),
      ),
    );
  }
}

/// Section heading (e.g. "SETTINGS", "HIGH SCORES").
class ArcadeHeading extends StatelessWidget {
  const ArcadeHeading(this.text, {super.key, this.color = NeonTheme.neonPink});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 20,
        color: color,
        letterSpacing: 5,
        shadows: [Shadow(color: color, blurRadius: 10)],
      ),
    );
  }
}

class _ArcadeFooter extends StatelessWidget {
  const _ArcadeFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          _copyright,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          _rights,
          style: TextStyle(
            fontFamily: 'monospace',
            color: Colors.white24,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 14,
          width: 220,
          child: CustomPaint(painter: _HazardBarPainter()),
        ),
      ],
    );
  }
}

/// Faint neon lines radiating from a point, as in the mockups.
class _VectorField extends StatelessWidget {
  const _VectorField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _VectorFieldPainter(), size: Size.infinite);
  }
}

class _VectorFieldPainter extends CustomPainter {
  static const _colors = [
    NeonTheme.neonPink,
    NeonTheme.neonCyan,
    NeonTheme.neonGreen,
    NeonTheme.neonPurple,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.5, size.height * 0.42);
    final reach = size.width + size.height;
    for (var i = 0; i < 16; i++) {
      final angle = i * pi / 8 + 0.15;
      final end = origin + Offset(cos(angle), sin(angle)) * reach;
      canvas.drawLine(
        origin,
        end,
        Paint()
          ..color = _colors[i % _colors.length].withValues(alpha: 0.10)
          ..strokeWidth = 1,
      );
    }
    canvas.drawCircle(
      origin,
      2,
      Paint()..color = NeonTheme.dangerRed.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 12.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Cyan corner brackets.
    const len = 34.0;
    final bracket = Paint()
      ..color = NeonTheme.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    void corner(Offset c, double dx, double dy) {
      canvas.drawLine(c, c + Offset(len * dx, 0), bracket);
      canvas.drawLine(c, c + Offset(0, len * dy), bracket);
    }

    corner(rect.topLeft, 1, 1);
    corner(rect.topRight, -1, 1);
    corner(rect.bottomLeft, 1, -1);
    corner(rect.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _HazardBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cells = 11;
    final cellW = size.width / cells;
    for (var i = 0; i < cells; i++) {
      final rect = Rect.fromLTWH(i * cellW, 0, cellW - 2, size.height);
      if (i.isEven) {
        canvas.drawRect(
          rect,
          Paint()..color = NeonTheme.neonPurple.withValues(alpha: 0.8),
        );
      } else {
        canvas.save();
        canvas.clipRect(rect);
        final paint = Paint()
          ..color = NeonTheme.neonPurple.withValues(alpha: 0.5)
          ..strokeWidth = 1.5;
        for (var x = -size.height; x < cellW + size.height; x += 4) {
          canvas.drawLine(
            Offset(i * cellW + x, size.height),
            Offset(i * cellW + x + size.height, 0),
            paint,
          );
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
