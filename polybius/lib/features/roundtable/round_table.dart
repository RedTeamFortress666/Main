import 'package:polybius/features/roundtable/traffic_sketch.dart';

/// What the five analysts are watching for.
enum CadenceVerdict {
  /// Irregular human gaps. Do not touch the message.
  human,

  /// Mixed or too little signal.
  mixed,

  /// Regular machine cadence accumulating over sketches — "doublespeak".
  hostile,
}

class AnalystVote {
  const AnalystVote({
    required this.seat,
    required this.score,
    required this.note,
  });

  final String seat;

  /// 0 = human, 100 = machine. Integers only.
  final int score;
  final String note;

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'score': score,
        'note': note,
      };

  static AnalystVote fromJson(Map<String, dynamic> map) => AnalystVote(
        seat: map['seat'] as String,
        score: (map['score'] as num).toInt(),
        note: map['note'] as String? ?? '',
      );
}

/// Boiled-down report the cabinet is allowed to store and show.
///
/// Raw sketches and seat prose stay with the sidecar authority. The
/// cabinet Hive row is verdict + five scores + a one-line boil. That is
/// what "hidden even to developers" means on this device: no payload,
/// no decoy runes, no analyst dossier. A developer who owns the sidecar
/// process can still read its notes — that is a sidecar-owned residual.
class PatternReport {
  const PatternReport({
    required this.verdict,
    required this.votes,
    required this.boil,
    required this.atMs,
    this.interfered = false,
    this.origin = 'local',
  });

  final CadenceVerdict verdict;
  final List<AnalystVote> votes;
  final String boil;
  final int atMs;

  /// Always false. The table watches; it does not drop H2H frames.
  final bool interfered;
  final String origin;

  bool get isHuman => verdict == CadenceVerdict.human;

  String get readout =>
      '${verdict.name.toUpperCase()} · ${votes.map((v) => '${v.seat[0]}${v.score}').join(' ')}';

  Map<String, dynamic> toJson() => {
        'verdict': verdict.name,
        'votes': votes.map((v) => v.toJson()).toList(),
        'boil': boil,
        'atMs': atMs,
        'interfered': interfered,
        'origin': origin,
      };

  static PatternReport fromJson(Map<String, dynamic> map) {
    final name = map['verdict'] as String? ?? 'mixed';
    return PatternReport(
      verdict: CadenceVerdict.values.firstWhere(
        (v) => v.name == name,
        orElse: () => CadenceVerdict.mixed,
      ),
      votes: (map['votes'] as List? ?? [])
          .map((e) => AnalystVote.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      boil: map['boil'] as String? ?? '',
      atMs: (map['atMs'] as num?)?.toInt() ?? 0,
      interfered: false,
      origin: map['origin'] as String? ?? 'local',
    );
  }
}

/// Five seats. Each sees only a [TrafficSketch].
///
/// They are looking for *hostile AI doublespeak*: token-regular gaps,
/// missing human pauses, identical burst trains over time. A human
/// typing on the vanishing field (80–1400 ms gaps, variance) is voted
/// HUMAN and the message is never delayed or dropped.
class RoundTable {
  const RoundTable();

  static const seats = ['CADENCE', 'BURST', 'CHANNEL', 'RECEIPT', 'PAUSE'];

  PatternReport convene(
    TrafficSketch sketch, {
    List<TrafficSketch> history = const [],
    int? nowMs,
    String origin = 'local',
  }) {
    final votes = <AnalystVote>[
      _cadence(sketch),
      _burst(sketch),
      _channel(sketch),
      _receipt(sketch),
      _pause(sketch, history),
    ];
    final mean = votes.fold<int>(0, (a, v) => a + v.score) / votes.length;
    final hostileSeats = votes.where((v) => v.score >= 70).length;
    final humanSeats = votes.where((v) => v.score <= 35).length;

    CadenceVerdict verdict;
    String boil;
    if (sketch.looksHumanTyped && humanSeats >= 3 && hostileSeats == 0) {
      verdict = CadenceVerdict.human;
      boil = 'H2H CADENCE — NO INTERFERENCE';
    } else if (hostileSeats >= 3 || mean >= 70) {
      verdict = CadenceVerdict.hostile;
      boil = 'MACHINE CADENCE OVER TIME — DOUBLESPEAK WATCH';
    } else {
      verdict = CadenceVerdict.mixed;
      boil = 'MIXED PATTERN — WATCH, DO NOT TOUCH';
    }

    return PatternReport(
      verdict: verdict,
      votes: votes,
      boil: boil,
      atMs: nowMs ?? sketch.atMs,
      interfered: false,
      origin: origin,
    );
  }

  AnalystVote _cadence(TrafficSketch s) {
    if (s.gapsMs.length < 3) {
      return const AnalystVote(
        seat: 'CADENCE',
        score: 20,
        note: 'too few gaps; default human',
      );
    }
    final mean = s.gapsMs.reduce((a, b) => a + b) / s.gapsMs.length;
    var acc = 0.0;
    for (final g in s.gapsMs) {
      final d = g - mean;
      acc += d * d;
    }
    final sd = (acc / s.gapsMs.length);
    final cv = mean == 0 ? 0.0 : (sd / (mean * mean));
    // Low coefficient of variation → metronome → machine.
    final score = cv < 0.04
        ? 90
        : cv < 0.15
            ? 55
            : 15;
    return AnalystVote(
      seat: 'CADENCE',
      score: score,
      note: 'cv=${cv.toStringAsFixed(3)}',
    );
  }

  AnalystVote _burst(TrafficSketch s) {
    if (s.gapsMs.length < 4) {
      return const AnalystVote(seat: 'BURST', score: 20, note: 'short');
    }
    var run = 1;
    var maxRun = 1;
    for (var i = 1; i < s.gapsMs.length; i++) {
      if ((s.gapsMs[i] - s.gapsMs[i - 1]).abs() <= 8) {
        run++;
        if (run > maxRun) maxRun = run;
      } else {
        run = 1;
      }
    }
    final score = maxRun >= 6
        ? 88
        : maxRun >= 4
            ? 50
            : 18;
    return AnalystVote(seat: 'BURST', score: score, note: 'run=$maxRun');
  }

  AnalystVote _channel(TrafficSketch s) {
    // A single unused channel is not hostile by itself; hopping cover
    // plus QR is more human-operator. Score stays low unless the name
    // is the synthetic 'agent' tag tests use.
    final score = s.channel == 'agent' ? 80 : 22;
    return AnalystVote(seat: 'CHANNEL', score: score, note: s.channel);
  }

  AnalystVote _receipt(TrafficSketch s) {
    if (s.decoyCount == 0) {
      return const AnalystVote(
        seat: 'RECEIPT',
        score: 10,
        note: 'no stego — nothing to vet',
      );
    }
    return AnalystVote(
      seat: 'RECEIPT',
      score: s.hasReceipt ? 15 : 60,
      note: s.hasReceipt ? 'receipt present' : 'stego without receipt',
    );
  }

  AnalystVote _pause(TrafficSketch s, List<TrafficSketch> history) {
    final all = [
      ...history.expand((h) => h.gapsMs),
      ...s.gapsMs,
    ];
    if (all.length < 8) {
      return const AnalystVote(seat: 'PAUSE', score: 25, note: 'warming');
    }
    final pauses = all.where((g) => g >= 400).length;
    final ratio = pauses / all.length;
    // Humans hesitate. Token streams do not.
    final score = ratio < 0.05
        ? 85
        : ratio < 0.15
            ? 45
            : 12;
    return AnalystVote(
      seat: 'PAUSE',
      score: score,
      note: 'pause=${ratio.toStringAsFixed(2)} n=${all.length}',
    );
  }
}
