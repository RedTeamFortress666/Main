/// Structured flasher progress / log event.
///
/// EventChannel payload shape:
/// `{stage, percent, message, level, target, detail, ts, ok}`
class FlasherEvent {
  FlasherEvent({
    required this.stage,
    required this.message,
    this.percent,
    this.level = FlasherLogLevel.info,
    this.target = '',
    this.detail = '',
    DateTime? ts,
    this.ok,
  }) : ts = ts ?? DateTime.now();

  final String stage;
  final double? percent;
  final String message;
  final FlasherLogLevel level;
  final String target;
  final String detail;
  final DateTime ts;
  final bool? ok;

  factory FlasherEvent.fromMap(Map<dynamic, dynamic> m) {
    final levelRaw = (m['level'] as String?) ?? 'info';
    return FlasherEvent(
      stage: (m['stage'] as String?) ?? (m['type'] as String?) ?? 'log',
      percent: (m['percent'] as num?)?.toDouble() ??
          (m['progress'] is num
              ? (m['progress'] as num).toDouble()
              : (m['value'] is Map
                  ? ((m['value'] as Map)['progress'] as num?)?.toDouble()
                  : (m['value'] is num ? (m['value'] as num).toDouble() : null))),
      message: (m['message'] as String?) ??
          (m['value'] is String
              ? m['value'] as String
              : (m['value'] is Map
                  ? ((m['value'] as Map)['message'] as String?) ?? ''
                  : '')),
      level: FlasherLogLevel.values.firstWhere(
        (e) => e.name == levelRaw,
        orElse: () => FlasherLogLevel.info,
      ),
      target: (m['target'] as String?) ?? '',
      detail: (m['detail'] as String?) ?? '',
      ts: m['ts'] is int
          ? DateTime.fromMillisecondsSinceEpoch(m['ts'] as int)
          : DateTime.now(),
      ok: m['ok'] as bool?,
    );
  }

  Map<String, dynamic> toMap() => {
        'stage': stage,
        'percent': percent,
        'message': message,
        'level': level.name,
        'target': target,
        'detail': detail,
        'ts': ts.millisecondsSinceEpoch,
        'ok': ok,
      };

  String toLogLine() {
    final t = ts.toIso8601String().substring(11, 19);
    final pct = percent == null ? '----' : '${(percent! * 100).toStringAsFixed(0)}%';
    final tgt = target.isEmpty ? '-' : target;
    final okS = ok == null ? '' : (ok! ? ' OK' : ' FAIL');
    final det = detail.isEmpty ? '' : ' | $detail';
    return '[$t][$tgt][$stage][$pct][${level.name}]$okS $message$det';
  }
}

enum FlasherLogLevel { debug, info, warn, error, success }

class OperationReport {
  OperationReport({
    required this.target,
    required this.title,
  });

  final String target;
  final String title;
  final List<ReportItem> items = [];
  bool cancelled = false;

  void add({
    required String name,
    required bool ok,
    String detail = '',
  }) {
    items.add(ReportItem(name: name, ok: ok, detail: detail));
  }

  bool get allOk => items.isNotEmpty && items.every((i) => i.ok);

  String summary() {
    final ok = items.where((i) => i.ok).length;
    final fail = items.length - ok;
    final buf = StringBuffer('$title — $ok ok, $fail failed');
    if (cancelled) buf.write(' (cancelled)');
    buf.writeln();
    for (final i in items) {
      buf.writeln('${i.ok ? "✓" : "✗"} ${i.name}${i.detail.isEmpty ? "" : " — ${i.detail}"}');
    }
    return buf.toString().trimRight();
  }
}

class ReportItem {
  ReportItem({required this.name, required this.ok, this.detail = ''});
  final String name;
  final bool ok;
  final String detail;
}
