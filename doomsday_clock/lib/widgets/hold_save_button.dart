import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/noir_theme.dart';

/// Press to save immediately. Hold to fire [onHoldComplete] after [holdMs].
class HoldSaveButton extends StatefulWidget {
  const HoldSaveButton({
    super.key,
    required this.holdMs,
    required this.onTapSave,
    required this.onHoldComplete,
  });

  final int holdMs;
  final VoidCallback onTapSave;
  final VoidCallback onHoldComplete;

  @override
  State<HoldSaveButton> createState() => _HoldSaveButtonState();
}

class _HoldSaveButtonState extends State<HoldSaveButton> {
  Timer? _timer;
  double _progress = 0;
  bool _completed = false;
  int _ticks = 0;

  void _start() {
    _timer?.cancel();
    _completed = false;
    _ticks = 0;
    setState(() => _progress = 0);
    const stepMs = 50;
    final steps = (widget.holdMs / stepMs).ceil().clamp(1, 1000);
    _timer = Timer.periodic(const Duration(milliseconds: stepMs), (_) {
      _ticks++;
      if (!mounted) return;
      setState(() => _progress = (_ticks / steps).clamp(0.0, 1.0));
      if (_ticks >= steps && !_completed) {
        _completed = true;
        _timer?.cancel();
        widget.onHoldComplete();
      }
    });
  }

  void _end() {
    _timer?.cancel();
    _timer = null;
    final wasComplete = _completed;
    _completed = false;
    _ticks = 0;
    if (mounted) setState(() => _progress = 0);
    if (!wasComplete) {
      widget.onTapSave();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: Semantics(
        button: true,
        label: 'Save',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: NoirTheme.panel,
            border: Border.all(color: NoirTheme.neonCyan),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              if (_progress > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 3,
                    backgroundColor: NoirTheme.voidBlack,
                    color: NoirTheme.neonMagenta,
                  ),
                ),
              const Text(
                'Save',
                style: TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                  color: NoirTheme.neonCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
