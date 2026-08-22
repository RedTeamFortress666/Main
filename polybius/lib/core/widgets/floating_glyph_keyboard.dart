import 'dart:math';

import 'package:flutter/material.dart';
import 'package:polybius/core/crypto/unpredictable_shift.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Floating Polybius-square keyboard.
///
/// Each glyph occupies a keycap, spins while the pulse is visible, then fades
/// out. While invisible the arrangement is replaced by an unpredictable
/// scramble so the next layout cannot be inferred from the last one. Pulse
/// length is re-rolled in 0.8–1.3s every cycle.
class FloatingGlyphKeyboard extends StatefulWidget {
  const FloatingGlyphKeyboard({
    super.key,
    this.columns = 5,
    this.interactive = false,
    this.onGlyph,
    this.shift,
  });

  final int columns;
  final bool interactive;
  final ValueChanged<String>? onGlyph;

  /// Optional engine (tests inject a seeded [UnpredictableShift]).
  final UnpredictableShift? shift;

  @override
  State<FloatingGlyphKeyboard> createState() => FloatingGlyphKeyboardState();
}

class FloatingGlyphKeyboardState extends State<FloatingGlyphKeyboard>
    with TickerProviderStateMixin {
  late final UnpredictableShift _shift;
  late final AnimationController _pulse;
  late final AnimationController _spin;

  late List<String> _glyphs;
  late List<double> _spinRates;
  late List<double> _floatPhase;

  List<String> get glyphs => List<String>.unmodifiable(_glyphs);

  @override
  void initState() {
    super.initState();
    _shift = widget.shift ?? UnpredictableShift(columns: widget.columns);
    _glyphs = _shift.scramble(
      PolybiusSquareGlyphs.keys,
      canonical: PolybiusSquareGlyphs.keys,
    );
    _spinRates = [
      for (var i = 0; i < _glyphs.length; i++) _shift.nextSpinRadiansPerSecond(),
    ];
    _floatPhase = [
      for (var i = 0; i < _glyphs.length; i++) i * 0.73,
    ];

    _pulse = AnimationController(vsync: this, duration: _shift.nextPulse())
      ..addStatusListener(_onPulseStatus);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulse.forward();
  }

  void _onPulseStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _reshuffle();
    _pulse.duration = _shift.nextPulse();
    _pulse.forward(from: 0);
  }

  void _reshuffle() {
    if (!mounted) return;
    setState(() {
      _glyphs = _shift.scramble(
        _glyphs,
        canonical: PolybiusSquareGlyphs.keys,
      );
      _spinRates = [
        for (var i = 0; i < _glyphs.length; i++)
          _shift.nextSpinRadiansPerSecond(),
      ];
    });
  }

  @override
  void dispose() {
    _pulse.removeStatusListener(_onPulseStatus);
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// Triangle-like visibility: hidden at 0 and 1, fully visible at mid-pulse.
  double get visibility {
    final t = _pulse.value;
    return sin(pi * t).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'A POLYBĪUS SQU\\R3 floating glyph keyboard',
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _spin]),
        builder: (context, _) {
          final visible = visibility;
          final spinning = visible > 0.08;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _glyphs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final glyph = _glyphs[index];
              final angle =
                  spinning ? _spinRates[index] * _spin.value * 8 : 0.0;
              final bob = sin(_spin.value * 2 * pi + _floatPhase[index]) * 3;
              return _GlyphKey(
                glyph: glyph,
                opacity: visible,
                angle: angle,
                bob: bob,
                color: _colorFor(glyph),
                onTap: widget.interactive
                    ? () => widget.onGlyph?.call(glyph)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  static Color _colorFor(String glyph) {
    const palette = [
      NeonTheme.neonCyan,
      NeonTheme.neonPink,
      NeonTheme.neonGreen,
      NeonTheme.neonYellow,
      NeonTheme.neonPurple,
      NeonTheme.neonOrange,
    ];
    return palette[glyph.codeUnitAt(0) % palette.length];
  }
}

class _GlyphKey extends StatelessWidget {
  const _GlyphKey({
    required this.glyph,
    required this.opacity,
    required this.angle,
    required this.bob,
    required this.color,
    this.onTap,
  });

  final String glyph;
  final double opacity;
  final double angle;
  final double bob;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final keycap = Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, bob),
        child: Transform.rotate(
          angle: angle,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.85), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35 * opacity),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                glyph,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                  shadows: [Shadow(color: color, blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return keycap;
    return GestureDetector(onTap: onTap, child: keycap);
  }
}
