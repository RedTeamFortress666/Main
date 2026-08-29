import 'dart:async';

import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/vanishing_buffer.dart';

/// Shows the last typed glyph, then fades it to empty in [buffer.fadeMs].
class VanishingField extends StatefulWidget {
  const VanishingField({
    super.key,
    required this.buffer,
    this.label = 'PLAINTEXT',
  });

  final VanishingBuffer buffer;
  final String label;

  @override
  State<VanishingField> createState() => _VanishingFieldState();
}

class _VanishingFieldState extends State<VanishingField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  int _seen = -1;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.buffer.fadeMs),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant VanishingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (_seen == widget.buffer.generation) return;
    _seen = widget.buffer.generation;
    _hold?.cancel();
    if (widget.buffer.flash.isEmpty) {
      _fade.value = 0;
      return;
    }
    _fade.value = 1;
    _hold = Timer(const Duration(milliseconds: 80), () {
      if (mounted) _fade.reverse();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    return Container(
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: NeonTheme.neonGreen),
        color: NeonTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonGreen,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.buffer.flash.isEmpty ? ' ' : widget.buffer.flash,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.dangerRed,
                    fontSize: 28,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
