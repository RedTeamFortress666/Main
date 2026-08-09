import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

/// Plaintext field that respects [VeilMode]:
/// - [VeilMode.normal]: ordinary visible text
/// - [VeilMode.echo]: each new character flashes then fades
/// - [VeilMode.matrix]: characters are not shown (value still held for encrypt)
class GhostPlaintextField extends StatefulWidget {
  const GhostPlaintextField({
    super.key,
    required this.controller,
    required this.mode,
    required this.label,
    required this.labelColor,
    this.maxLines = 3,
    this.style,
  });

  final TextEditingController controller;
  final VeilMode mode;
  final String label;
  final Color labelColor;
  final int maxLines;
  final TextStyle? style;

  @override
  State<GhostPlaintextField> createState() => _GhostPlaintextFieldState();
}

class _GhostPlaintextFieldState extends State<GhostPlaintextField> {
  /// Recently typed glyphs still fading out (echo mode).
  final Map<int, _FadeGlyph> _fading = {};
  String _prev = '';
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _prev = widget.controller.text;
    widget.controller.addListener(_onText);
    _tick = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (_fading.isEmpty) return;
      final now = DateTime.now();
      _fading.removeWhere((_, g) => now.difference(g.born).inMilliseconds > 900);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _tick?.cancel();
    super.dispose();
  }

  void _onText() {
    final text = widget.controller.text;
    if (widget.mode == VeilMode.echo && text.length > _prev.length) {
      // Fresh characters at the end (simple append detection).
      for (var i = _prev.length; i < text.length; i++) {
        _fading[i] = _FadeGlyph(text[i], DateTime.now());
      }
    }
    if (text.length < _prev.length) {
      _fading.removeWhere((i, _) => i >= text.length);
    }
    _prev = text;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ??
        const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 16);

    // Matrix / echo: keep a real editable field but paint its text transparent.
    final hideGlyphs =
        widget.mode == VeilMode.matrix || widget.mode == VeilMode.echo;
    final fieldStyle = hideGlyphs
        ? baseStyle.copyWith(color: Colors.transparent)
        : baseStyle;

    return Stack(
      children: [
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          style: fieldStyle,
          cursorColor: widget.mode == VeilMode.matrix
              ? const Color(0xFF00FF66)
              : baseStyle.color,
          inputFormatters: widget.mode == VeilMode.matrix
              ? const []
              : const <TextInputFormatter>[],
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: widget.labelColor),
            border: const OutlineInputBorder(),
            helperText: widget.mode == VeilMode.matrix
                ? 'MATRIX VEIL — plaintext hidden'
                : widget.mode == VeilMode.echo
                    ? 'ECHO — letters fade after typing'
                    : null,
            helperStyle: TextStyle(
              color: widget.mode == VeilMode.matrix
                  ? const Color(0xFF00FF66)
                  : widget.labelColor.withValues(alpha: 0.7),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ),
        if (widget.mode == VeilMode.echo)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: _EchoOverlay(
                  text: widget.controller.text,
                  fading: _fading,
                  style: baseStyle,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FadeGlyph {
  _FadeGlyph(this.char, this.born);
  final String char;
  final DateTime born;

  double opacityAt(DateTime now) {
    final ms = now.difference(born).inMilliseconds;
    if (ms < 180) return 1;
    if (ms >= 900) return 0;
    return 1 - ((ms - 180) / 720);
  }
}

class _EchoOverlay extends StatelessWidget {
  const _EchoOverlay({
    required this.text,
    required this.fading,
    required this.style,
  });

  final String text;
  final Map<int, _FadeGlyph> fading;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spans = <InlineSpan>[];
    for (var i = 0; i < text.length; i++) {
      final fade = fading[i];
      if (fade != null) {
        final o = fade.opacityAt(now);
        spans.add(TextSpan(
          text: text[i],
          style: style.copyWith(color: style.color?.withValues(alpha: o)),
        ));
      } else {
        // Settled characters leave only a faint dust mark.
        spans.add(TextSpan(
          text: '·',
          style: style.copyWith(
            color: (style.color ?? Colors.white).withValues(alpha: 0.12),
            letterSpacing: 1,
          ),
        ));
      }
    }
    return RichText(text: TextSpan(children: spans));
  }
}
