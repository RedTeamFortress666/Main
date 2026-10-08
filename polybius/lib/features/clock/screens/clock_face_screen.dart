import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/clock/clock_ritual.dart';
import 'package:polybius/features/clock/clock_session.dart';
import 'package:polybius/features/clock/roman24.dart';
import 'package:polybius/features/clock/widgets/analog_clock_dial.dart';

/// Public clock face: analog 24h Roman dial, alarm legend, cherry glass.
class ClockFaceScreen extends ConsumerStatefulWidget {
  const ClockFaceScreen({super.key});

  @override
  ConsumerState<ClockFaceScreen> createState() => _ClockFaceScreenState();
}

class _ClockFaceScreenState extends ConsumerState<ClockFaceScreen> {
  final _alarm = TextEditingController();
  Timer? _hold;
  String? _toast;

  @override
  void initState() {
    super.initState();
    _alarm.text = ref.read(clockSessionProvider).alarm;
  }

  @override
  void dispose() {
    _hold?.cancel();
    _alarm.dispose();
    super.dispose();
  }

  void _startAlarmHold() {
    _hold?.cancel();
    _hold = Timer(ClockRitual.setAlarmHold, () {
      final session = ref.read(clockSessionProvider.notifier);
      session.setAlarm(_alarm.text);
      if (session.deskReady) {
        context.go('/clock/desk');
      } else {
        setState(() => _toast = 'Alarm saved');
      }
    });
  }

  void _endAlarmHold() => _hold?.cancel();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(clockSessionProvider);
    final cherry = session.cherryActive;
    final accent = cherry ? const Color(0xFFFF2A4D) : const Color(0xFFC9A227);

    if (!session.unlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/clock');
      });
    }

    return Scaffold(
      backgroundColor: cherry ? const Color(0xFF140008) : const Color(0xFF07070A),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Row(
                  children: [
                    const Text(
                      'CLOCK',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        color: Colors.white54,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Roman24.format(session.hour, session.minute),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: accent,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: AnalogClockDial(
                    hour: session.hour,
                    minute: session.minute,
                    cherry: cherry,
                  ),
                ),
                const SizedBox(height: 16),
                _StepperRow(
                  label: 'HOUR',
                  value: session.hour.toString().padLeft(2, '0'),
                  roman: Roman24.hour(session.hour),
                  color: accent,
                  onMinus: () => ref
                      .read(clockSessionProvider.notifier)
                      .setFace(hour: session.hour - 1),
                  onPlus: () => ref
                      .read(clockSessionProvider.notifier)
                      .setFace(hour: session.hour + 1),
                ),
                _StepperRow(
                  label: 'MIN',
                  value: session.minute.toString().padLeft(2, '0'),
                  roman: Roman24.minute(session.minute),
                  color: accent,
                  onMinus: () => ref
                      .read(clockSessionProvider.notifier)
                      .setFace(minute: session.minute - 1),
                  onPlus: () => ref
                      .read(clockSessionProvider.notifier)
                      .setFace(minute: session.minute + 1),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'DARTH CHERRY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  subtitle: const Text(
                    'Crimson glass',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  value: cherry,
                  activeThumbColor: const Color(0xFFFF2A4D),
                  onChanged: (v) =>
                      ref.read(clockSessionProvider.notifier).setCherryActive(v),
                ),
                TextField(
                  controller: _alarm,
                  onChanged: (v) =>
                      ref.read(clockSessionProvider.notifier).setAlarm(v),
                  style: TextStyle(fontFamily: 'monospace', color: accent),
                  decoration: InputDecoration(
                    labelText: 'ALARM',
                    labelStyle: TextStyle(color: accent.withValues(alpha: 0.7)),
                    hintText: 'Roman legend',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  key: const Key('set-alarm'),
                  onLongPressStart: (_) => _startAlarmHold(),
                  onLongPressEnd: (_) => _endAlarmHold(),
                  onLongPressCancel: _endAlarmHold,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: accent, width: 1.6),
                    ),
                    child: Text(
                      'SET ALARM',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (_toast != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _toast!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ],
            ),
          ),
          if (session.showFalseAlarm) const _FalseAlarmBanner(),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.roman,
    required this.color,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final String roman;
  final Color color;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(label, style: const TextStyle(color: Colors.white38)),
          ),
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove)),
          Text(
            '$value  $roman',
            style: TextStyle(
              fontFamily: 'monospace',
              color: color,
              letterSpacing: 2,
            ),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _FalseAlarmBanner extends ConsumerWidget {
  const _FalseAlarmBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: Material(
        color: Colors.black87,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: NeonTheme.dangerRed, width: 2),
              color: const Color(0xFF22000A),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alarm, color: NeonTheme.dangerRed, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'ALARM',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    color: NeonTheme.dangerRed,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  ClockRitual.alarmLegend,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white70,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.read(clockSessionProvider.notifier).dismissFalseAlarm(),
                  child: const Text('DISMISS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
