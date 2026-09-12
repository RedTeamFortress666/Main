import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/patch_ledger.dart';

/// Side effects a weave may need. The patcher itself is pure policy.
///
/// Storage-backed in the app; no-op in tests. Each hook reports what is
/// true afterwards so the verify phase can re-scan honestly.
abstract class PatchHooks {
  /// Make sure the session box holds a V2 ticket. Returns whether it does.
  Future<bool> ensureTicket();

  /// Make sure a phosphor mixer exists. Returns it.
  Future<String> ensureMixer();

  /// Make sure the red-light vault is minted for the live operator.
  /// Returns whether a sealed vault now exists for them.
  Future<bool> ensureRedlightVault();

  /// Mint an ML-KEM-768 keypair under the device key.
  Future<bool> ensurePqKem();

  /// Bind a vet authority (sidecar if reachable, else local stand-in).
  Future<bool> ensureStegoVet();

  /// Convene an empty-warm round table so the watch is armed.
  Future<bool> ensureRoundTable();

  /// Pair a loopback glasses session for the live operator.
  Future<bool> ensureGlassesLink();

  const PatchHooks();
}

class NoopPatchHooks extends PatchHooks {
  const NoopPatchHooks();

  @override
  Future<bool> ensureTicket() async => false;

  @override
  Future<String> ensureMixer() async => '';

  @override
  Future<bool> ensureRedlightVault() async => false;

  @override
  Future<bool> ensurePqKem() async => false;

  @override
  Future<bool> ensureStegoVet() async => false;

  @override
  Future<bool> ensureRoundTable() async => false;

  @override
  Future<bool> ensureGlassesLink() async => false;
}

/// One remediation the patcher knows how to weave.
class PatchStep {
  const PatchStep({
    required this.leakId,
    required this.title,
    required this.action,
    required this.apply,
    this.sideEffect,
  });

  final String leakId;
  final String title;
  final String action;
  final CabinetPolicy Function(CabinetPolicy policy) apply;

  /// Optional storage work. Receives the snapshot as it stands and returns
  /// the snapshot as it stands afterwards.
  final Future<LeakSnapshot> Function(LeakSnapshot snap, PatchHooks hooks)?
      sideEffect;
}

/// Outcome of one weave, before it is chained into the ledger.
class WeaveResult {
  const WeaveResult({
    required this.before,
    required this.after,
    required this.policy,
    required this.snapshot,
    required this.entry,
  });

  final LeakReport before;
  final LeakReport after;
  final CabinetPolicy policy;

  /// Snapshot after side effects — what the live detector should see.
  final LeakSnapshot snapshot;

  /// Unchained entry (prevMac / mac empty). Storage fills the chain.
  final PatchLedgerEntry entry;

  int get appliedCount => entry.appliedCount;
}

/// Interwoven auto-patcher.
///
/// DETECT → APPLY → VERIFY → LEDGER. Runs inside the V2 handshake (step 05),
/// on session restore, when Darth Cherry arms, when a pool token syncs, and
/// from the Developer panel. It weaves [CabinetPolicy] and takes the storage
/// actions a policy flag alone cannot (ticket, mixer, red-light vault,
/// ML-KEM keypair, vet authority, round table, glasses pair). It does not
/// fetch or apply signed binaries — [SignatureService.verifyPayload] still
/// has no install path (BUILD.md) — and it does not hide a Hive dump.
class AutoPatcher {
  AutoPatcher._();

  static const String auditAction = 'AUTOPATCH';
  static const String tamperAction = 'LEDGER_TAMPER';

  /// Oldest entries are pruned past this. The first kept entry still carries
  /// its prevMac, so the surviving chain verifies.
  static const int ledgerCap = 64;

  static final List<PatchStep> steps = List.unmodifiable([
    PatchStep(
      leakId: 'session.legacy',
      title: 'V2 TICKET',
      action: 'issue device-bound MAC ticket into the session box',
      apply: (p) => p.copyWith(v2Session: true),
      sideEffect: (snap, hooks) async {
        final v2 = snap.sessionIsV2 || await hooks.ensureTicket();
        return snap.copyWith(sessionIsV2: v2);
      },
    ),
    PatchStep(
      leakId: 'phosphor.username',
      title: 'PHOSPHOR MIXER',
      action: 'key the glyph derangement from a stored random mixer',
      apply: (p) => p.copyWith(phosphorUsesMixer: true),
      sideEffect: (snap, hooks) async {
        final user = snap.operatorUsername ?? '';
        final weak = snap.mixer.isEmpty ||
            snap.mixer.length < 8 ||
            (user.isNotEmpty && snap.mixer == user);
        if (!weak) return snap.copyWith(derangeSecret: snap.mixer);
        final mixer = await hooks.ensureMixer();
        if (mixer.isEmpty) return snap;
        return snap.copyWith(mixer: mixer, derangeSecret: mixer);
      },
    ),
    PatchStep(
      leakId: 'cover.chrome',
      title: 'REAL-SEED CHROME',
      action: 'pin POOL / rotors / sync chrome to the real seed',
      apply: (p) => p.copyWith(chromeUsesRealSeed: true),
    ),
    PatchStep(
      leakId: 'v1.stego',
      title: 'V1 CLEAN',
      action: 'disable unused-master decoys on advanced V1',
      apply: (p) => p.copyWith(v1Stego: false),
    ),
    PatchStep(
      leakId: 'decrypt.density',
      title: 'DUAL DENSITY',
      action: 'DECRYPT tries 2-glyph then 3-glyph, keeps the longer read',
      apply: (p) => p.copyWith(autoDensity: true),
    ),
    PatchStep(
      leakId: 'cover.pin_gate',
      title: 'PIN GATE HOLD',
      action: 'cover PIN success keeps requiresPin so restart re-gates',
      apply: (p) => p.copyWith(persistCoverPinGate: true),
    ),
    PatchStep(
      leakId: 'glyphs.tofu',
      title: 'TOFU FILTER',
      action: 'drop control / modifier / unassigned runes from the master',
      apply: (p) => p.copyWith(filterTofu: true),
    ),
    PatchStep(
      leakId: 'redlight.vault',
      title: 'REDLIGHT SEAL',
      action:
          'seal lamp filter + key map in one AES vault bound to device and operator; gate render on a live ticket',
      apply: (p) => p.copyWith(sealRedlight: true),
      sideEffect: (snap, hooks) async {
        final sealed = snap.redlightSealed || await hooks.ensureRedlightVault();
        return snap.copyWith(redlightSealed: sealed);
      },
    ),
    PatchStep(
      leakId: 'envelope.pq',
      title: 'ML-KEM HYBRID',
      action: 'mint ML-KEM-768 and seal courier envelopes as X25519 + Kyber',
      apply: (p) => p.copyWith(hybridPq: true),
      sideEffect: (snap, hooks) async {
        final live = snap.hybridPqLive || await hooks.ensurePqKem();
        return snap.copyWith(hybridPqLive: live);
      },
    ),
    PatchStep(
      leakId: 'stego.vet',
      title: 'STEGO VET',
      action:
          'bind a vet authority; decoy fingerprints get a receipt, notes stay off Hive',
      apply: (p) => p.copyWith(stegoVet: true),
      sideEffect: (snap, hooks) async {
        final bound = snap.stegoVetBound || await hooks.ensureStegoVet();
        return snap.copyWith(stegoVetBound: bound);
      },
    ),
    PatchStep(
      leakId: 'roundtable.watch',
      title: 'ROUND TABLE',
      action:
          'arm five cadence seats; they watch sketches and never drop H2H frames',
      apply: (p) => p.copyWith(roundTable: true),
      sideEffect: (snap, hooks) async {
        final armed = snap.roundTableArmed || await hooks.ensureRoundTable();
        return snap.copyWith(roundTableArmed: armed);
      },
    ),
    PatchStep(
      leakId: 'glasses.hud',
      title: 'GLASSES HUD',
      action:
          'pair a device-bound HUD session; cabinet face becomes attract-mode',
      apply: (p) => p.copyWith(glassesHud: true),
      sideEffect: (snap, hooks) async {
        final paired = snap.glassesPaired || await hooks.ensureGlassesLink();
        return snap.copyWith(glassesPaired: paired);
      },
    ),
  ]);

  /// Pure policy weave — no ledger, no side effects. Kept for callers that
  /// only need the target policy.
  static CabinetPolicy weave() => CabinetPolicy.woven;

  /// Full pipeline. [snapshot] is the cabinet as it stands before the weave.
  static Future<WeaveResult> run({
    required LeakSnapshot snapshot,
    required String trigger,
    required int seq,
    PatchHooks hooks = const NoopPatchHooks(),
    DateTime? now,
  }) async {
    // DETECT
    final before = LeakDetector.scan(snapshot);

    // APPLY
    var policy = snapshot.policy;
    var live = snapshot;
    for (final step in steps) {
      policy = step.apply(policy);
      final effect = step.sideEffect;
      if (effect != null) {
        live = await effect(live, hooks);
      }
    }
    live = live.copyWith(policy: policy);

    // VERIFY
    final after = LeakDetector.scan(live);

    // LEDGER
    final results = <PatchResult>[];
    for (final finding in after.findings) {
      final prior = before.byId(finding.id)?.severity ?? LeakSeverity.open;
      final step = _stepFor(finding.id);
      results.add(
        PatchResult(
          leakId: finding.id,
          title: step?.title ?? finding.title,
          action: step?.action ?? 'named, not remediable in-app',
          before: prior,
          after: finding.severity,
          outcome: _outcome(step, prior, finding.severity),
        ),
      );
    }
    final at = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    final entry = PatchLedgerEntry(
      seq: seq,
      trigger: trigger,
      atMs: at,
      openBefore: before.openCount,
      openAfter: after.openCount,
      policyCanonical: policy.canonical,
      results: results,
    );
    return WeaveResult(
      before: before,
      after: after,
      policy: policy,
      snapshot: live,
      entry: entry,
    );
  }

  /// Legacy convenience: scan as if the woven policy were live.
  static LeakReport afterWeave(LeakSnapshot snap) {
    return LeakDetector.scan(snap.copyWith(policy: weave()));
  }

  static PatchStep? _stepFor(String leakId) {
    for (final s in steps) {
      if (s.leakId == leakId) return s;
    }
    return null;
  }

  static PatchOutcome _outcome(
    PatchStep? step,
    LeakSeverity before,
    LeakSeverity after,
  ) {
    if (after == LeakSeverity.residual) return PatchOutcome.residual;
    if (after == LeakSeverity.open) return PatchOutcome.pending;
    if (step == null) {
      // Detector-only finding (ledger chain, cover record when absent).
      return before == LeakSeverity.patched
          ? PatchOutcome.held
          : PatchOutcome.applied;
    }
    return before == LeakSeverity.open
        ? PatchOutcome.applied
        : PatchOutcome.held;
  }
}
