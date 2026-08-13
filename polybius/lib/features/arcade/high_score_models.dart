/// Persisted arcade high-score entry (shared over pool-sync QR).
library;

class HighScoreEntry {
  const HighScoreEntry({
    required this.name,
    required this.score,
    required this.at,
  });

  final String name;
  final int score;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'n': name,
        's': score,
        't': at.millisecondsSinceEpoch,
      };

  factory HighScoreEntry.fromJson(Map<String, dynamic> json) => HighScoreEntry(
        name: (json['n'] as String? ?? 'ANON').trim(),
        score: (json['s'] as num?)?.toInt() ?? 0,
        at: DateTime.fromMillisecondsSinceEpoch(
          (json['t'] as num?)?.toInt() ?? 0,
        ),
      );

  HighScoreEntry copyWith({String? name, int? score, DateTime? at}) =>
      HighScoreEntry(
        name: name ?? this.name,
        score: score ?? this.score,
        at: at ?? this.at,
      );
}
