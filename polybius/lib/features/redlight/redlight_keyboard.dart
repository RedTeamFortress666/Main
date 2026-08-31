import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/cabinet_lamp.dart';
import 'package:polybius/features/redlight/glyph_derangement.dart';
import 'package:polybius/features/redlight/keyclick.dart';
import 'package:polybius/features/redlight/vanishing_buffer.dart';

/// Dual-layer keyboard: QWERTY in cyan (house lights), session derangement
/// in phosphor red (cabinet lamp). When [lampOn] the derangement is what
/// is typed; under house lights the keys type themselves so demo/debug
/// remains practical.
class RedlightKeyboard extends StatefulWidget {
  const RedlightKeyboard({
    super.key,
    required this.derangement,
    required this.buffer,
    required this.lampOn,
    this.audio = true,
    this.onChanged,
  });

  final GlyphDerangement derangement;
  final VanishingBuffer buffer;
  final bool lampOn;
  final bool audio;
  final VoidCallback? onChanged;

  @override
  State<RedlightKeyboard> createState() => _RedlightKeyboardState();
}

class _RedlightKeyboardState extends State<RedlightKeyboard> {
  bool _shift = false;

  static const _rows = <List<String>>[
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  void _type(String physical) {
    final isDigit = RegExp(r'^\d$').hasMatch(physical);
    final typed = isDigit
        ? (widget.lampOn ? widget.derangement.mapGlyph(physical) : physical)
        : widget.lampOn
            ? widget.derangement.type(physical, shift: _shift)
            : (_shift ? physical.toUpperCase() : physical.toLowerCase());
    widget.buffer.append(typed);
    Keyclick.tick(audio: widget.audio);
    widget.onChanged?.call();
    setState(() {});
  }

  void _space() {
    widget.buffer.append(' ');
    Keyclick.tick(audio: widget.audio);
    widget.onChanged?.call();
    setState(() {});
  }

  void _backspace() {
    widget.buffer.backspace();
    Keyclick.tick(audio: widget.audio);
    widget.onChanged?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows) _row(row),
        Row(
          children: [
            _special(_shift ? 'SHIFT*' : 'SHIFT', () {
              setState(() => _shift = !_shift);
              Keyclick.tick(audio: widget.audio);
            }),
            _special('SPACE', _space, flex: 3),
            _special('DEL', _backspace),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> keys) {
    return Row(
      children: [
        for (final k in keys)
          Expanded(
            child: _Keycap(
              key: ValueKey<String>('cabinet-key-$k'),
              house: k,
              phosphor: widget.derangement.mapGlyph(k),
              onTap: () => _type(k),
            ),
          ),
      ],
    );
  }

  Widget _special(String label, VoidCallback onTap, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: NeonTheme.neonPink.withValues(alpha: 0.4)),
              color: NeonTheme.surface,
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: NeonTheme.neonPink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keycap extends StatelessWidget {
  const _Keycap({
    super.key,
    required this.house,
    required this.phosphor,
    required this.onTap,
  });

  final String house;
  final String phosphor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: NeonTheme.neonCyan.withValues(alpha: 0.35)),
            color: const Color(0xCC0A0014),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.cherry.withValues(alpha: 0.18),
                blurRadius: 6,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                house,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: CabinetLamp.houseCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                phosphor,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: CabinetLamp.phosphor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
