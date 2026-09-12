import 'dart:math';

import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// False attract-mode for a non-intended viewer.
///
/// Looks like an idle 1981 cabinet: CRT snow, INSERT COIN, a scrolling
/// high-score crawl. It is not a crash screen and it is not the cipher.
/// The intended viewer (paired HUD / this-device-is-the-glasses) never
/// sees this; they get the red-light keyboard.
class CoverScreensaver extends StatefulWidget {
  const CoverScreensaver({
    super.key,
    this.onOperatorWake,
    this.canWake = false,
  });

  /// Called when an authenticated operator taps to dismiss.
  final VoidCallback? onOperatorWake;
  final bool canWake;

  @override
  State<CoverScreensaver> createState() => _CoverScreensaverState();
}

class _CoverScreensaverState extends State<CoverScreensaver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = Random(1981);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.canWake ? widget.onOperatorWake : null,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _AttractPainter(t: _ctrl.value, rng: _rng),
            child: const SizedBox.expand(
              child: IgnorePointer(
                child: _AttractCopy(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttractCopy extends StatelessWidget {
  const _AttractCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PØLYBĪUS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 28,
            letterSpacing: 8,
            color: NeonTheme.neonCyan.withValues(alpha: 0.85),
            shadows: const [
              Shadow(color: NeonTheme.neonCyan, blurRadius: 18),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'INSERT  COIN',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 6,
            color: NeonTheme.neonYellow,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'HIGH SCORES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 3,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'AAA  198100   CLX  661980   DEV  000001',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            letterSpacing: 1,
            color: NeonTheme.neonGreen,
          ),
        ),
        const SizedBox(height: 36),
        Text(
          'ATTRACT MODE',
          key: const ValueKey<String>('cover-screensaver'),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            letterSpacing: 4,
            color: Colors.white.withValues(alpha: 0.28),
          ),
        ),
      ],
    );
  }
}

class _AttractPainter extends CustomPainter {
  _AttractPainter({required this.t, required this.rng});

  final double t;
  final Random rng;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050010),
    );
    final star = Paint()..color = const Color(0x66FFFFFF);
    for (var i = 0; i < 48; i++) {
      final x = (size.width * ((i * 37 + t * 80) % 100) / 100);
      final y = (size.height * ((i * 19 + t * 40) % 100) / 100);
      canvas.drawCircle(Offset(x, y), 0.8, star);
    }
    final scan = Paint()..color = const Color(0x14FF2A6D);
    final y = (size.height * ((t * 2) % 1.0));
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, 18), scan);
  }

  @override
  bool shouldRepaint(covariant _AttractPainter old) => old.t != t;
}
