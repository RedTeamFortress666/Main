import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

/// Hidden dev/admin "SYS_CRASH" report screen (reached by holding GAME OVER).
///
/// Flow: enter at least 6 words describing the incident, put the game file
/// number in the diagnostic code box, hold SAVE AS DRAFT for 3 seconds until
/// it glitches, then press SEND to proceed to the dev/admin login gate.
class ErrorScreen extends ConsumerStatefulWidget {
  const ErrorScreen({super.key});

  @override
  ConsumerState<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends ConsumerState<ErrorScreen> {
  final _incident = TextEditingController();
  final _diagnostic = TextEditingController();
  final _crashId = (Random().nextInt(0xffffff)).toRadixString(16).padLeft(6, '0');

  Timer? _holdTimer;
  bool _holdingDraft = false;
  bool _draftSaved = false;
  bool _glitch = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill the diagnostic code with the bound game file number if present.
    ref.read(storageServiceProvider).getGameFileNumber().then((code) {
      if (code != null && mounted) _diagnostic.text = code;
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _incident.dispose();
    _diagnostic.dispose();
    super.dispose();
  }

  int get _wordCount =>
      _incident.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  void _startDraftHold() {
    if (_wordCount < 6) {
      setState(() => _error = 'DESCRIBE INCIDENT IN AT LEAST 6 WORDS');
      return;
    }
    setState(() {
      _holdingDraft = true;
      _error = null;
    });
    _holdTimer = Timer(
      const Duration(milliseconds: AppConstants.langSelectHoldMs),
      () {
        if (!_holdingDraft) return;
        setState(() {
          _holdingDraft = false;
          _draftSaved = true;
          _glitch = true;
        });
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted) setState(() => _glitch = false);
        });
      },
    );
  }

  void _endDraftHold() {
    setState(() => _holdingDraft = false);
    _holdTimer?.cancel();
  }

  void _send() {
    if (_wordCount < 6) {
      setState(() => _error = 'DESCRIBE INCIDENT IN AT LEAST 6 WORDS');
      return;
    }
    if (!_draftSaved) {
      setState(() => _error = 'HOLD SAVE AS DRAFT FIRST');
      return;
    }
    // Proceed to the dev/admin login gate (only accepts privileged codes).
    context.go('/devportal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _glitch ? NeonTheme.neonPurple.withValues(alpha: 0.2) : Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                border: Border.all(color: NeonTheme.dangerRed, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: NeonTheme.dangerRed.withValues(alpha: 0.4),
                      blurRadius: 24),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      '⚠ ERROR ⚠',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 30,
                        color: NeonTheme.dangerRed,
                        letterSpacing: 4,
                        shadows: [Shadow(color: NeonTheme.dangerRed, blurRadius: 12)],
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      'SYS_CRASH #$_crashId',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: NeonTheme.neonOrange,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'An unexpected fault terminated the process. Report to '
                    'admin to aid debugging? Describe incident below;',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _box(
                    child: TextField(
                      controller: _incident,
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontFamily: 'monospace', color: Colors.white),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'describe incident…',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                    color: NeonTheme.dangerRed.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  _box(
                    child: TextField(
                      controller: _diagnostic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.white54,
                          letterSpacing: 4),
                      decoration: const InputDecoration.collapsed(
                        hintText: 'diagnostic code',
                        hintStyle: TextStyle(color: Colors.white24, letterSpacing: 4),
                      ),
                    ),
                    color: NeonTheme.neonCyan.withValues(alpha: 0.4),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: const TextStyle(
                            color: NeonTheme.dangerRed,
                            fontFamily: 'monospace',
                            fontSize: 11)),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _btn('SEND', NeonTheme.neonGreen, _send),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onLongPressStart: (_) => _startDraftHold(),
                        onLongPressEnd: (_) => _endDraftHold(),
                        onLongPressCancel: _endDraftHold,
                        child: _btnBox(
                          _draftSaved
                              ? 'DRAFT SAVED'
                              : (_holdingDraft ? 'HOLD…' : 'SAVE AS DRAFT?'),
                          NeonTheme.neonYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: _btn(
                      'CANCEL / RETURN',
                      NeonTheme.dangerRed,
                      () => context.pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _box({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: child,
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: _btnBox(label, color));
  }

  Widget _btnBox(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
