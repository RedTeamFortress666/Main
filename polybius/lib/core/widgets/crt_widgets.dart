import 'dart:math';
import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// CRT scanline + vignette overlay for retro arcade aesthetic.
class CrtOverlay extends StatelessWidget {
  const CrtOverlay({
    super.key,
    required this.child,
    this.intensity = 0.7,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanlinePainter(intensity: intensity),
          ),
        ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3 * intensity),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonTheme.scanline.withValues(alpha: intensity);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

/// Brief glitch flash overlay used during unlock rituals.
class GlitchOverlay extends StatefulWidget {
  const GlitchOverlay({
    super.key,
    required this.active,
    this.onComplete,
    this.child,
  });

  final bool active;
  final VoidCallback? onComplete;
  final Widget? child;

  @override
  State<GlitchOverlay> createState() => _GlitchOverlayState();
}

class _GlitchOverlayState extends State<GlitchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  bool _flashing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset so a finished flash never leaves a hit-test barrier.
        setState(() => _flashing = false);
        _controller.value = 0;
        widget.onComplete?.call();
      }
    });
    if (widget.active) {
      _startFlash();
    }
  }

  void _startFlash() {
    setState(() => _flashing = true);
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(GlitchOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startFlash();
    } else if (!widget.active && oldWidget.active) {
      setState(() => _flashing = false);
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.child != null) widget.child!,
        // Visual-only: never absorb taps (this previously froze the menu
        // after the PØLYBĪUS title-hold glitch because the finished flash
        // layer stayed mounted at opacity 0 and blocked all input).
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (!_flashing || _controller.value == 0) {
                return const SizedBox.shrink();
              }
              final offset =
                  (_random.nextDouble() - 0.5) * 20 * _controller.value;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Container(
                  color: [
                    NeonTheme.neonPink,
                    NeonTheme.neonCyan,
                    Colors.white,
                  ][_random.nextInt(3)]
                      .withValues(alpha: 0.15 * (1 - _controller.value)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Neon-styled arcade menu button.
class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = NeonTheme.neonCyan,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.color,
            width: _pressed ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _pressed ? 0.8 : 0.4),
              blurRadius: _pressed ? 20 : 10,
              spreadRadius: _pressed ? 2 : 0,
            ),
          ],
          color: widget.color.withValues(alpha: _pressed ? 0.15 : 0.05),
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.color,
            letterSpacing: 3,
            shadows: [
              Shadow(color: widget.color, blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subliminal MKUltra phrase flash.
class SubliminalFlash extends StatefulWidget {
  const SubliminalFlash({super.key, required this.phrases});

  final List<String> phrases;

  @override
  State<SubliminalFlash> createState() => _SubliminalFlashState();
}

class _SubliminalFlashState extends State<SubliminalFlash> {
  final _random = Random();
  String? _phrase;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _scheduleFlash();
  }

  void _scheduleFlash() {
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(8000)), () {
      if (!mounted) return;
      setState(() {
        _phrase = widget.phrases[_random.nextInt(widget.phrases.length)];
        _visible = true;
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) setState(() => _visible = false);
        _scheduleFlash();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _phrase == null) return const SizedBox.shrink();
    return Positioned(
      left: _random.nextDouble() * 100,
      top: 50 + _random.nextDouble() * 200,
      child: Text(
        _phrase!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: NeonTheme.neonPink.withValues(alpha: 0.3),
          letterSpacing: 2,
        ),
      ),
    );
  }
}
