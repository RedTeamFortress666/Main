import 'dart:math';

import 'package:flutter/material.dart';
import 'package:polybius/core/crypto/unpredictable_shift.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Darth Cherry v3 disappearing / rotating glyph keyboard.
///
/// Glyphs pulse visible then vanish; while invisible the layout is replaced
/// by an unpredictable scramble. Taps emit the latin character mapped for
/// *this pulse only* — the map never leaves RAM.
class FloatingGlyphKeyboard extends StatefulWidget {
  const FloatingGlyphKeyboard({
    super.key,
    this.columns = 6,
    this.interactive = false,
    this.onChar,
    this.shift,
  });

  final int columns;
  final bool interactive;
  final ValueChanged<String>? onChar;
  final UnpredictableShift? shift;

  @override
  State<FloatingGlyphKeyboard> createState() => FloatingGlyphKeyboardState();
}

class FloatingGlyphKeyboardState extends State<FloatingGlyphKeyboard>
    with TickerProviderStateMixin {
  static const latin = [
    'A', 'B', 'C', 'D', 'E', 'F',
    'G', 'H', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X',
    'Y', 'Z', '0', '1', '2', '3',
    '4', '5', '6', '7', '8', '9',
  ];

  late final UnpredictableShift _shift;
  late final AnimationController _pulse;
  late final AnimationController _spin;

  late List<String> _glyphs;
  late Map<String, String> _map;
  late List<double> _spinRates;
  late List<double> _floatPhase;

  List<String> get glyphs => List<String>.unmodifiable(_glyphs);

  @override
  void initState() {
    super.initState();
    _shift = widget.shift ?? UnpredictableShift(columns: widget.columns);
    _glyphs = List<String>.from(PolybiusSquareGlyphs.cherryKeys);
    _map = _shift.latinMap(_glyphs, latin);
    _spinRates = [
      for (var i = 0; i < _glyphs.length; i++) _shift.nextSpinRadiansPerSecond(),
    ];
    _floatPhase = [for (var i = 0; i < _glyphs.length; i++) i * 0.73];

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
        canonical: PolybiusSquareGlyphs.cherryKeys,
      );
      _map = _shift.latinMap(_glyphs, latin);
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

  double get visibility {
    final t = _pulse.value;
    return sin(pi * t).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Darth Cherry v3 disappearing glyph keyboard',
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulse, _spin]),
        builder: (context, _) {
          final visible = visibility;
          final spinning = visible > 0.08;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _glyphs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 1.1,
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
                color: index.isEven ? NeonTheme.cherryBright : NeonTheme.cherryGold,
                onTap: widget.interactive
                    ? () {
                        final ch = _map[glyph];
                        if (ch != null) widget.onChar?.call(ch);
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
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
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Transform.rotate(
            angle: angle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: NeonTheme.cherryGlass.withValues(alpha: 0.85),
                border: Border.all(
                  color: color.withValues(alpha: 0.9),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4 * opacity),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  glyph,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    shadows: [Shadow(color: color, blurRadius: 8)],
                  ),
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
