import 'package:polybius/core/constants/master_glyphs.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';

enum LeakSeverity { open, patched, residual }

class LeakFinding {
  const LeakFinding({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String id;
  final String title;
  final String detail;
  final LeakSeverity severity;
}

class LeakReport {
  const LeakReport(this.findings);

  final List<LeakFinding> findings;

  int get openCount =>
      findings.where((f) => f.severity == LeakSeverity.open).length;
  int get patchedCount =>
      findings.where((f) => f.severity == LeakSeverity.patched).length;
  int get residualCount =>
      findings.where((f) => f.severity == LeakSeverity.residual).length;

  LeakFinding? byId(String id) {
    for (final f in findings) {
      if (f.id == id) return f;
    }
    return null;
  }
}

/// Inputs the detector can actually observe. No network, no binary scan.
class LeakSnapshot {
  const LeakSnapshot({
    required this.policy,
    required this.mixer,
    this.operatorUsername,
    this.sessionIsV2 = false,
    this.cabinetRecordExists = false,
    this.masterJunk,
    this.derangeSecret,
  });

  final CabinetPolicy policy;
  final String mixer;
  final String? operatorUsername;
  final bool sessionIsV2;
  final bool cabinetRecordExists;
  final int? masterJunk;

  /// Secret actually passed into [GlyphDerangement]. Empty = unused.
  final String? derangeSecret;
}

/// Darth Cherry leak detector.
///
/// Names real surfaces. Residuals stay residuals — Hive cover records and
/// client-owned binaries are not "fixed" by a score bar.
class LeakDetector {
  LeakDetector._();

  static LeakReport scan(LeakSnapshot snap) {
    final junk = snap.masterJunk ?? MasterGlyphs.junkCount;
    final user = snap.operatorUsername;
    final derange = snap.derangeSecret;
    final mixerLooksLikeUser = user != null &&
        user.isNotEmpty &&
        (snap.mixer == user || derange == user);

    return LeakReport([
      LeakFinding(
        id: 'session.legacy',
        title: 'BARE SESSION',
        detail: snap.policy.v2Session && snap.sessionIsV2
            ? 'V2 ticket MAC-bound to this device key'
            : 'Session box is a bare operator name',
        severity: snap.policy.v2Session && snap.sessionIsV2
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'phosphor.username',
        title: 'PHOSPHOR MAP',
        detail: snap.policy.phosphorUsesMixer && !mixerLooksLikeUser
            ? 'Derangement keyed by stored mixer, not the nameplate'
            : 'Keyboard map was recomputable from visible username',
        severity: snap.policy.phosphorUsesMixer && !mixerLooksLikeUser
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'cover.chrome',
        title: 'COVER CHROME',
        detail: snap.policy.chromeUsesRealSeed
            ? 'POOL / rotors stay on the real seed during cover'
            : 'Cover seed was painted onto POOL and rotor gear',
        severity: snap.policy.chromeUsesRealSeed
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'v1.stego',
        title: 'V1 DECOYS',
        detail: !snap.policy.v1Stego
            ? 'Advanced V1 encrypts 2 glyphs/char, no unused-master decoys'
            : 'V1 ciphertext mixed unused-master decoys into HELLO',
        severity:
            !snap.policy.v1Stego ? LeakSeverity.patched : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'decrypt.density',
        title: 'DECRYPT DENSITY',
        detail: snap.policy.autoDensity
            ? 'DECRYPT tries 2-glyph then 3-glyph without the last chip'
            : 'Cherry 3-glyph left V1 ciphertext unreadable',
        severity: snap.policy.autoDensity
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'cover.pin_gate',
        title: 'COVER PIN GATE',
        detail: snap.policy.persistCoverPinGate
            ? 'Cover success keeps the Hive PIN gate; restart re-challenges'
            : 'Cover success cleared requiresPin — restart restored the real cabinet',
        severity: snap.policy.persistCoverPinGate
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'glyphs.tofu',
        title: 'TOFU POOL',
        detail: snap.policy.filterTofu && junk == 0
            ? 'Master cabinet is curated pictographs only'
            : 'Unassigned / modifier runes were drawn into the pool',
        severity: snap.policy.filterTofu && junk == 0
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'cabinet.hive',
        title: 'COVER RECORD',
        detail: snap.cabinetRecordExists
            ? 'Hive still shows a cover cabinet exists — local-forensic, not hidden'
            : 'No cover cabinet stored on this operator',
        severity: snap.cabinetRecordExists
            ? LeakSeverity.residual
            : LeakSeverity.patched,
      ),
      LeakFinding(
        id: 'client.owned',
        title: 'CLIENT OWNED',
        detail:
            'A device the operator controls can patch any verifier. No score bar changes that.',
        severity: LeakSeverity.residual,
      ),
    ]);
  }
}
