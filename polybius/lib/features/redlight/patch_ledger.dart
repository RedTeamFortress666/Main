import 'package:polybius/features/redlight/leak_detector.dart';

/// What one patch step did to one leak surface during a weave.
enum PatchOutcome {
  /// OPEN before, PATCHED after — the weave changed something.
  applied,

  /// Already PATCHED; the weave re-asserted it.
  held,

  /// Still OPEN after apply. Needs an operator action the patcher cannot
  /// take (e.g. no session yet, so no ticket to issue).
  pending,

  /// Not remediable in-app. Named, not hidden.
  residual,
}

class PatchResult {
  const PatchResult({
    required this.leakId,
    required this.title,
    required this.action,
    required this.before,
    required this.after,
    required this.outcome,
  });

  final String leakId;
  final String title;

  /// Verb the patcher performed. Shown in the ledger, not marketing copy.
  final String action;
  final LeakSeverity before;
  final LeakSeverity after;
  final PatchOutcome outcome;

  String get canonical =>
      '$leakId:${before.name}>${after.name}:${outcome.name}';

  Map<String, dynamic> toJson() => {
        'leakId': leakId,
        'title': title,
        'action': action,
        'before': before.name,
        'after': after.name,
        'outcome': outcome.name,
      };

  factory PatchResult.fromJson(Map<dynamic, dynamic> json) => PatchResult(
        leakId: json['leakId'] as String,
        title: json['title'] as String,
        action: json['action'] as String? ?? '',
        before: LeakSeverity.values.byName(json['before'] as String),
        after: LeakSeverity.values.byName(json['after'] as String),
        outcome: PatchOutcome.values.byName(json['outcome'] as String),
      );
}

/// One weave. Entries chain: [prevMac] is the previous entry's [mac], and
/// [mac] is HMAC(device key, prevMac | canonical). Editing an old entry or
/// dropping one from the middle breaks verification.
class PatchLedgerEntry {
  const PatchLedgerEntry({
    required this.seq,
    required this.trigger,
    required this.atMs,
    required this.openBefore,
    required this.openAfter,
    required this.policyCanonical,
    required this.results,
    this.prevMac = '',
    this.mac = '',
  });

  final int seq;

  /// LOGIN, RESTORE, CHERRY, SYNC, MANUAL, BASELINE …
  final String trigger;
  final int atMs;
  final int openBefore;
  final int openAfter;
  final String policyCanonical;
  final List<PatchResult> results;
  final String prevMac;
  final String mac;

  int get appliedCount =>
      results.where((r) => r.outcome == PatchOutcome.applied).length;
  int get heldCount =>
      results.where((r) => r.outcome == PatchOutcome.held).length;
  int get pendingCount =>
      results.where((r) => r.outcome == PatchOutcome.pending).length;
  int get residualCount =>
      results.where((r) => r.outcome == PatchOutcome.residual).length;

  DateTime get at => DateTime.fromMillisecondsSinceEpoch(atMs, isUtc: true);

  /// Bytes the MAC covers. Excludes [mac] itself, includes [prevMac].
  String get canonical => [
        'seq=$seq',
        'trigger=$trigger',
        'at=$atMs',
        'open=$openBefore>$openAfter',
        'policy=$policyCanonical',
        'results=${results.map((r) => r.canonical).join(',')}',
        'prev=$prevMac',
      ].join('|');

  /// Short readout for the CRT: `#3 LOGIN 1→0`.
  String get readout => '#$seq $trigger $openBefore→$openAfter';

  PatchLedgerEntry withChain({required String prevMac, required String mac}) =>
      PatchLedgerEntry(
        seq: seq,
        trigger: trigger,
        atMs: atMs,
        openBefore: openBefore,
        openAfter: openAfter,
        policyCanonical: policyCanonical,
        results: results,
        prevMac: prevMac,
        mac: mac,
      );

  Map<String, dynamic> toJson() => {
        'seq': seq,
        'trigger': trigger,
        'atMs': atMs,
        'openBefore': openBefore,
        'openAfter': openAfter,
        'policy': policyCanonical,
        'results': results.map((r) => r.toJson()).toList(),
        'prevMac': prevMac,
        'mac': mac,
      };

  factory PatchLedgerEntry.fromJson(Map<dynamic, dynamic> json) =>
      PatchLedgerEntry(
        seq: json['seq'] as int,
        trigger: json['trigger'] as String,
        atMs: json['atMs'] as int,
        openBefore: json['openBefore'] as int,
        openAfter: json['openAfter'] as int,
        policyCanonical: json['policy'] as String? ?? '',
        results: (json['results'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => PatchResult.fromJson(Map<dynamic, dynamic>.from(m)))
            .toList(),
        prevMac: json['prevMac'] as String? ?? '',
        mac: json['mac'] as String? ?? '',
      );
}

/// The persisted chain plus whether it still verifies.
class PatchLedger {
  const PatchLedger({this.entries = const [], this.intact = true});

  final List<PatchLedgerEntry> entries;

  /// False when any entry's MAC or link to its predecessor fails.
  final bool intact;

  PatchLedgerEntry? get latest => entries.isEmpty ? null : entries.last;
  int get nextSeq => (latest?.seq ?? 0) + 1;
  bool get isEmpty => entries.isEmpty;

  static const empty = PatchLedger();
}
