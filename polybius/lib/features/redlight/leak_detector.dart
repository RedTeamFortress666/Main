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
    this.ledgerIntact = true,
    this.ledgerEntries = 0,
    this.redlightSealed = false,
    this.hybridPqLive = false,
    this.stegoVetBound = false,
    this.roundTableArmed = false,
    this.glassesPaired = false,
  });

  final CabinetPolicy policy;
  final String mixer;
  final String? operatorUsername;
  final bool sessionIsV2;
  final bool cabinetRecordExists;
  final int? masterJunk;

  /// Secret actually passed into [GlyphDerangement]. Empty = unused.
  final String? derangeSecret;

  /// Patch-ledger MAC chain still verifies under the device key.
  final bool ledgerIntact;
  final int ledgerEntries;

  /// An AES-sealed red-light vault exists for the live operator.
  final bool redlightSealed;

  /// ML-KEM-768 keypair is minted on this device.
  final bool hybridPqLive;

  /// A vet authority (local stand-in or sidecar) will issue receipts.
  final bool stegoVetBound;

  /// At least one pattern report has been convened.
  final bool roundTableArmed;

  /// Glasses session verifies under this device key for the operator.
  final bool glassesPaired;

  LeakSnapshot copyWith({
    CabinetPolicy? policy,
    String? mixer,
    String? operatorUsername,
    bool? sessionIsV2,
    bool? cabinetRecordExists,
    int? masterJunk,
    String? derangeSecret,
    bool? ledgerIntact,
    int? ledgerEntries,
    bool? redlightSealed,
    bool? hybridPqLive,
    bool? stegoVetBound,
    bool? roundTableArmed,
    bool? glassesPaired,
  }) =>
      LeakSnapshot(
        policy: policy ?? this.policy,
        mixer: mixer ?? this.mixer,
        operatorUsername: operatorUsername ?? this.operatorUsername,
        sessionIsV2: sessionIsV2 ?? this.sessionIsV2,
        cabinetRecordExists: cabinetRecordExists ?? this.cabinetRecordExists,
        masterJunk: masterJunk ?? this.masterJunk,
        derangeSecret: derangeSecret ?? this.derangeSecret,
        ledgerIntact: ledgerIntact ?? this.ledgerIntact,
        ledgerEntries: ledgerEntries ?? this.ledgerEntries,
        redlightSealed: redlightSealed ?? this.redlightSealed,
        hybridPqLive: hybridPqLive ?? this.hybridPqLive,
        stegoVetBound: stegoVetBound ?? this.stegoVetBound,
        roundTableArmed: roundTableArmed ?? this.roundTableArmed,
        glassesPaired: glassesPaired ?? this.glassesPaired,
      );
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
        id: 'redlight.vault',
        title: 'REDLIGHT VAULT',
        detail: snap.policy.sealRedlight && snap.redlightSealed
            ? 'Lamp filter + key map AES-sealed to this device and operator; render needs a live ticket'
            : 'Lamp constants compiled in; key map keyed by a loose Hive value; rendered without a ticket',
        severity: snap.policy.sealRedlight && snap.redlightSealed
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'envelope.pq',
        title: 'ML-KEM HYBRID',
        detail: snap.policy.hybridPq && snap.hybridPqLive
            ? 'X25519 + ML-KEM-768 envelopes; HKDF(ss_x || ss_kyber)'
            : 'Courier envelopes were X25519-only; PQ slot empty',
        severity: snap.policy.hybridPq && snap.hybridPqLive
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'stego.vet',
        title: 'STEGO VET',
        detail: snap.policy.stegoVet && snap.stegoVetBound
            ? 'Decoy fingerprints receipted by a vet authority; notes stay off-device'
            : 'Unused-master decoys left the cabinet without a sidecar receipt',
        severity: snap.policy.stegoVet && snap.stegoVetBound
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'roundtable.watch',
        title: 'ROUND TABLE',
        detail: snap.policy.roundTable && snap.roundTableArmed
            ? 'Five seats watch cadence only; H2H is never delayed or dropped'
            : 'No communication-pattern watch; machine cadence would pass silent',
        severity: snap.policy.roundTable && snap.roundTableArmed
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'glasses.hud',
        title: 'GLASSES HUD',
        detail: snap.policy.glassesHud && snap.glassesPaired
            ? 'Phosphor on the paired HUD; cabinet face is attract-mode'
            : 'Red-light keyboard painted on the cabinet for any shoulder',
        severity: snap.policy.glassesHud && snap.glassesPaired
            ? LeakSeverity.patched
            : LeakSeverity.open,
      ),
      LeakFinding(
        id: 'ledger.chain',
        title: 'PATCH LEDGER',
        detail: !snap.ledgerIntact
            ? 'Ledger MAC chain broken — a weave record was edited or removed'
            : snap.ledgerEntries == 0
                ? 'No weave recorded yet on this device'
                : '${snap.ledgerEntries} weave(s) chained under the device key',
        severity: snap.ledgerIntact ? LeakSeverity.patched : LeakSeverity.open,
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
