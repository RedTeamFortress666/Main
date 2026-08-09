import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/conflict_zones.dart';
import '../theme/noir_theme.dart';

class ClockTab extends StatefulWidget {
  const ClockTab({super.key});

  @override
  State<ClockTab> createState() => _ClockTabState();
}

class _ClockTabState extends State<ClockTab> {
  late ZoneClock _zone;
  late Timer _timer;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _zone = ConflictZones.zones.first;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime _localFor(ZoneClock z) {
    // Flutter DateTime doesn't bundle full TZDB without a package; use fixed
    // offsets approximated from common zones for the cyberpunk board.
    final offsetHours = _approxOffset(z.iana);
    return _now.add(Duration(hours: offsetHours));
  }

  int _approxOffset(String iana) {
    // Standard (non-DST) display offsets for threat board readability.
    const map = {
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
    final local = _localFor(_zone);
    final color = NoirTheme.threatColor(_zone.threat);
    final timeStr = DateFormat('HH:mm:ss').format(local);
    final dateStr = DateFormat('EEE · yyyy-MM-dd').format(local);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('WORLD CLOCK · THREAT BAND',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 28),
            ],
            color: NoirTheme.panel,
          ),
          child: Column(
            children: [
              Text(
                timeStr,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 56,
                      fontFamily: 'monospace',
                      color: color,
                      letterSpacing: 4,
                    ),
              ),
              const SizedBox(height: 6),
              Text(dateStr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: NoirTheme.mist.withValues(alpha: 0.7))),
              const SizedBox(height: 12),
              Text(
                _zone.label.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: NoirTheme.mist,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _zone.threat.name.toUpperCase(),
                style: TextStyle(
                  color: color,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(_zone.rationale, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 6),
        Text(
          'Source: ${_zone.source}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.5),
              ),
        ),
        const SizedBox(height: 18),
        Text('SELECT TIMEZONE', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final z in ConflictZones.zones)
              ChoiceChip(
                label: Text(z.label),
                selected: z.id == _zone.id,
                selectedColor: NoirTheme.threatColor(z.threat).withValues(alpha: 0.35),
                backgroundColor: NoirTheme.panel,
                labelStyle: TextStyle(
                  color: NoirTheme.threatColor(z.threat),
                  fontSize: 12,
                ),
                side: BorderSide(color: NoirTheme.threatColor(z.threat).withValues(alpha: 0.5)),
                onSelected: (_) => setState(() => _zone = z),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _legend(),
      ],
    );
  }

  Widget _legend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LEGEND', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _leg(ThreatLevel.peace, 'Peace / reference'),
        _leg(ThreatLevel.tension, 'Tension / elevated politics'),
        _leg(ThreatLevel.crisis, 'Crisis / militarised pressure'),
        _leg(ThreatLevel.conflict, 'Currently engaged in conflict'),
      ],
    );
  }

  Widget _leg(ThreatLevel t, String label) {
    final c = NoirTheme.threatColor(t);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 14, height: 14, color: c),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
