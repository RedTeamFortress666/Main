import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/noir_theme.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.visibleMonth,
    required this.selected,
    required this.onSelectDay,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime visibleMonth;
  final DateTime selected;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sunday = 0
    final cells = <Widget>[];
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(visibleMonth.year, visibleMonth.month, day);
      final isSelected = date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
      final isToday = _isSameDay(date, DateTime.now());
      cells.add(
        InkWell(
          key: Key('day-${date.year}-${date.month}-${date.day}'),
          onTap: () => onSelectDay(date),
          child: Semantics(
            button: true,
            selected: isSelected,
            label: DateFormat('d MMMM yyyy').format(date),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? NoirTheme.neonCyan.withValues(alpha: 0.22)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? NoirTheme.neonCyan
                      : isToday
                          ? NoirTheme.neonMagenta.withValues(alpha: 0.5)
                          : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected ? NoirTheme.neonCyan : NoirTheme.mist,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NoirTheme.panel,
        border: Border.all(color: NoirTheme.neonCyan.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left, color: NoirTheme.neonCyan),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(visibleMonth),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right, color: NoirTheme.neonCyan),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _Dow('S'),
              _Dow('M'),
              _Dow('T'),
              _Dow('W'),
              _Dow('T'),
              _Dow('F'),
              _Dow('S'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: cells,
          ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Dow extends StatelessWidget {
  const _Dow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: NoirTheme.chrome,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
