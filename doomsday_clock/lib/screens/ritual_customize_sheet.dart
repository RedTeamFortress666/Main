import 'package:flutter/material.dart';

import '../services/planner_service.dart';
import '../services/ritual_settings_service.dart';
import '../theme/noir_theme.dart';

class RitualCustomizeSheet extends StatefulWidget {
  const RitualCustomizeSheet({super.key, this.initial});

  final RitualSettings? initial;

  static Future<RitualSettings?> show(
    BuildContext context, {
    RitualSettings? initial,
  }) {
    return showModalBottomSheet<RitualSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NoirTheme.panel,
      builder: (_) => RitualCustomizeSheet(initial: initial),
    );
  }

  @override
  State<RitualCustomizeSheet> createState() => _RitualCustomizeSheetState();
}

class _RitualCustomizeSheetState extends State<RitualCustomizeSheet> {
  late final TextEditingController _phrase;
  late final TextEditingController _month;
  late final TextEditingController _day;

  @override
  void initState() {
    super.initState();
    _phrase = TextEditingController(text: widget.initial?.phrase ?? '');
    _month = TextEditingController(
      text: '${widget.initial?.month ?? 11}',
    );
    _day = TextEditingController(text: '${widget.initial?.day ?? 5}');
  }

  @override
  void dispose() {
    _phrase.dispose();
    _month.dispose();
    _day.dispose();
    super.dispose();
  }

  RitualSettings? _buildSettings() {
    final phrase = _phrase.text.trim();
    final month = int.tryParse(_month.text.trim());
    final day = int.tryParse(_day.text.trim());
    if (phrase.isEmpty && month == null && day == null) return null;
    return RitualSettings(
      phrase: phrase.isEmpty ? null : phrase,
      month: month,
      day: day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CUSTOM VAULT UNLOCK',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: NoirTheme.neonCyan,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional — defaults stay ${PlannerService.rememberRememberPhrase} '
              'on 5 November if you skip.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NoirTheme.mist.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phrase,
              decoration: const InputDecoration(
                labelText: 'SECRET WORDS',
                labelStyle: TextStyle(color: NoirTheme.neonMagenta),
              ),
              style: const TextStyle(color: NoirTheme.mist),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _month,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MONTH',
                      labelStyle: TextStyle(color: NoirTheme.neonCyan),
                    ),
                    style: const TextStyle(color: NoirTheme.mist),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _day,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'DAY',
                      labelStyle: TextStyle(color: NoirTheme.neonCyan),
                    ),
                    style: const TextStyle(color: NoirTheme.mist),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, _buildSettings()),
              style: OutlinedButton.styleFrom(
                foregroundColor: NoirTheme.peace,
                side: const BorderSide(color: NoirTheme.peace),
              ),
              child: const Text('SAVE CUSTOM UNLOCK'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text(
                'KEEP DEFAULTS',
                style: TextStyle(color: NoirTheme.chrome),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
