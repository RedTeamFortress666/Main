import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/conflict_zones.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';

class ClockTab extends StatefulWidget {
  const ClockTab({super.key});

  @override
  State<ClockTab> createState() => _ClockTabState();
}

class _ClockTabState extends State<ClockTab> {
  late ZoneClock _zone;
  late Timer _timer;
  DateTime _utcNow = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _zone = ConflictZones.zones.first; // Brisbane
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _utcNow = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Fixed standard offsets (Brisbane has no DST).
  int _approxOffset(String iana) {
    const map = {
      'Australia/Brisbane': 10,
      'Australia/Sydney': 10, // note: ignores AEDT for board simplicity
      'UTC': 0,
      'America/New_York': -5,
      'Europe/London': 0,
      'Europe/Kyiv': 2,
      'Europe/Moscow': 3,
      'Asia/Jerusalem': 2,
      'Asia/Tehran': 3,
      'Asia/Taipei': 8,
      'Asia/Seoul': 9,
      'Africa/Khartoum': 2,
      'Africa/Cairo': 2,
    };
    return map[iana] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final local = _utcNow.add(Duration(hours: _approxOffset(_zone.iana)));
    final color = NoirTheme.threatColor(_zone.threat);
    final timeStr = DateFormat('HH:mm:ss').format(local);
    final dateStr = DateFormat('EEE · yyyy-MM-dd').format(local);
    final bne = _utcNow.add(const Duration(hours: 10));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('BRISBANE QLD · AEST (UTC+10)',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        NeonPanel(
          child: Column(
            children: [
              Text(
                DateFormat('HH:mm:ss').format(bne),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      color: NoirTheme.matrix,
                    ),
              ),
              Text(
                DateFormat('EEEE · d MMMM yyyy').format(bne),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Text('NO DAYLIGHT SAVING',
                  style: TextStyle(
                    color: NoirTheme.yellow,
                    letterSpacing: 2,
                    fontSize: 10,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('WORLD CLOCK · THREAT BAND',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        NeonPanel(
          color: color,
          child: Column(
            children: [
              Text(timeStr,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 44,
                        color: color,
                      )),
              Text(dateStr),
              const SizedBox(height: 8),
              Text(_zone.label.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(_zone.threat.name.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(_zone.rationale),
        Text('Source: ${_zone.source}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: NoirTheme.mist.withValues(alpha: 0.5),
                )),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final z in ConflictZones.zones)
              ChoiceChip(
                label: Text(z.label),
                selected: z.id == _zone.id,
                selectedColor:
                    NoirTheme.threatColor(z.threat).withValues(alpha: 0.35),
                backgroundColor: NoirTheme.panel,
                labelStyle: TextStyle(
                  color: NoirTheme.threatColor(z.threat),
                  fontSize: 11,
                ),
                side: BorderSide(
                  color: NoirTheme.threatColor(z.threat).withValues(alpha: 0.5),
                ),
                onSelected: (_) => setState(() => _zone = z),
              ),
          ],
        ),
      ],
    );
  }
}
