import '../theme/noir_theme.dart';

class BulletinSnapshot {
  const BulletinSnapshot({
    required this.secondsToMidnight,
    required this.headline,
    required this.summary,
    required this.sourceUrl,
    required this.fetchedAt,
    required this.fromNetwork,
  });

  final int secondsToMidnight;
  final String headline;
  final String summary;
  final String sourceUrl;
  final DateTime fetchedAt;
  final bool fromNetwork;

  String get minutesLabel {
    if (secondsToMidnight >= 60) {
      final m = secondsToMidnight / 60.0;
      return '${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)} minutes';
    }
    return '$secondsToMidnight seconds';
  }
}

class ZoneClock {
  const ZoneClock({
    required this.id,
    required this.label,
    required this.iana,
    required this.threat,
    required this.rationale,
    required this.source,
  });

  final String id;
  final String label;
  final String iana;
  final ThreatLevel threat;
  final String rationale;
  final String source;
}

class PlannerNote {
  PlannerNote({
    required this.id,
    required this.dayKey,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  String dayKey;
  String body;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayKey': dayKey,
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PlannerNote.fromJson(Map<String, dynamic> j) => PlannerNote(
        id: j['id'] as String,
        dayKey: j['dayKey'] as String,
        body: j['body'] as String,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}
