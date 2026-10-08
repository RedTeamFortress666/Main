import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

/// Hidden eyeball — nearly invisible without the red veil; solid when the
/// filter beacon is active. Tap = echo/fade typing. Hold through a 3s pupil
/// blink = matrix green veil (invisible plaintext).
class VeilEyeballButton extends ConsumerStatefulWidget {
  const VeilEyeballButton({super.key});

  @override
  ConsumerState<VeilEyeballButton> createState() => _VeilEyeballButtonState();
}

class _VeilEyeballButtonState extends ConsumerState<VeilEyeballButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  Timer? _holdTimer;
  bool _holding = false;
  bool _pupilClosed = false;

  @override
  void initState() {
    super.initState();
    // Blink cycle: every 3 seconds the pupil closes briefly.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _pupilClosed = true);
          Future<void>.delayed(const Duration(milliseconds: 120), () {
            if (mounted) setState(() => _pupilClosed = false);
          });
          _blink.forward(from: 0);
        }
      });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _blink.dispose();
    super.dispose();
  }

  void _onTap() {
    ref.read(veilProvider.notifier).toggleEcho();
  }

  void _onLongPressStart(LongPressStartDetails _) {
    _holding = true;
    _blink.forward(from: 0);
    // Engage matrix after one full blink period (~3s) while held.
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 3000), () {
      if (_holding && mounted) {
        ref.read(veilProvider.notifier).engageMatrix();
      }
    });
    setState(() {});
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _holding = false;
    _holdTimer?.cancel();
    if (ref.read(veilProvider).mode != VeilMode.matrix) {
      _blink.stop();
      _blink.value = 0;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final veil = ref.watch(veilProvider);
    if (!veil.eyeVisible) {
      // Steganographic ghost: deep crimson speck, almost lost on black.
      // Under a red filter it can still hint at presence without the beacon.
      return const SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(painter: _GhostEyePainter(opacity: 0.04)),
      );
    }

    // Keep blinking while matrix is engaged.
    if (veil.mode == VeilMode.matrix && !_blink.isAnimating) {
      _blink.forward(from: 0);
    }

    final pupilColor = veil.mode == VeilMode.matrix
        ? const Color(0xFFFF1010)
        : (_holding ? const Color(0xFFFF2222) : const Color(0xFF8B0000));

    return GestureDetector(
      onTap: _onTap,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: Tooltip(
        message: veil.mode == VeilMode.matrix
            ? 'MATRIX VEIL — tap to clear'
            : veil.mode == VeilMode.echo
                ? 'ECHO — letters fade (hold for matrix)'
                : 'Tap: fade-type · Hold 3s: matrix veil',
        child: SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _EyePainter(
              pupilColor: pupilColor,
              pupilClosed: _pupilClosed,
              mode: veil.mode,
              holding: _holding,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostEyePainter extends CustomPainter {
  const _GhostEyePainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Color.fromRGBO(60, 0, 0, opacity);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: size.width * 0.7, height: size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GhostEyePainter old) => old.opacity != opacity;
}

class _EyePainter extends CustomPainter {
  _EyePainter({
    required this.pupilColor,
    required this.pupilClosed,
    required this.mode,
    required this.holding,
  });

  final Color pupilColor;
  final bool pupilClosed;
  final VeilMode mode;
  final bool holding;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final sclera = Paint()
      ..color = mode == VeilMode.matrix
          ? const Color(0xFF0A2A0A)
          : const Color(0xFF2A0808);
    final outline = Paint()
      ..color = holding ? const Color(0xFFFF4444) : const Color(0xFFAA2222)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final eyeH = pupilClosed ? size.height * 0.08 : size.height * 0.42;
    final rect =
        Rect.fromCenter(center: c, width: size.width * 0.85, height: eyeH);
    canvas.drawOval(rect, sclera);
    canvas.drawOval(rect, outline);

    if (!pupilClosed) {
      final pupil = Paint()..color = pupilColor;
      canvas.drawCircle(c, size.shortestSide * 0.14, pupil);
      // Specular glint.
      canvas.drawCircle(
        c.translate(-2, -2),
        size.shortestSide * 0.04,
        Paint()..color = const Color(0x88FFAAAA),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EyePainter old) =>
      old.pupilColor != pupilColor ||
      old.pupilClosed != pupilClosed ||
      old.mode != mode ||
      old.holding != holding;
}
