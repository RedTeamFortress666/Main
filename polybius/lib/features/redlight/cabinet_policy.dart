/// Live remediations the interwoven auto-patcher applies.
///
/// These are configuration patches inside the running cabinet — not binary
/// updates. A user who owns the device can still patch the verifier out
/// (BUILD.md). The honest job is to stop the app from shipping known leaks
/// as the default path.
class CabinetPolicy {
  const CabinetPolicy({
    this.v1Stego = true,
    this.autoDensity = false,
    this.chromeUsesRealSeed = false,
    this.phosphorUsesMixer = false,
    this.persistCoverPinGate = false,
    this.v2Session = false,
    this.filterTofu = false,
    this.sealRedlight = false,
    this.hybridPq = false,
    this.stegoVet = false,
    this.roundTable = false,
    this.glassesHud = false,
  });

  /// Old V1 path stuffed unused-master decoys into ciphertext.
  final bool v1Stego;

  /// DECRYPT tries compact then cabinet instead of the last chip.
  final bool autoDensity;

  /// POOL / rotors / sync chrome always use the real pool seed.
  final bool chromeUsesRealSeed;

  /// Glyph keyboard derangement is keyed by a stored mixer, not username.
  final bool phosphorUsesMixer;

  /// Cover PIN success keeps requiresPin in Hive so restart re-gates.
  final bool persistCoverPinGate;

  /// Session box holds a V2 MAC ticket, not a bare username.
  final bool v2Session;

  /// Master glyph cabinet skips unassigned / modifier / control runes.
  final bool filterTofu;

  /// Lamp filter + keypress derangement live in one AES-sealed, operator-
  /// bound vault and render only behind a valid device ticket.
  final bool sealRedlight;

  /// Courier envelopes carry X25519 + ML-KEM-768.
  final bool hybridPq;

  /// Unused-master decoys must carry a sidecar/local vet receipt.
  final bool stegoVet;

  /// Round table watches cadence sketches; never reads H2H plaintext.
  final bool roundTable;

  /// Red-light HUD is glasses-paired; cabinet face is attract-mode.
  final bool glassesHud;

  /// Interwoven default — the patcher is the boot path, not a later click.
  static const woven = CabinetPolicy(
    v1Stego: false,
    autoDensity: true,
    chromeUsesRealSeed: true,
    phosphorUsesMixer: true,
    persistCoverPinGate: true,
    v2Session: true,
    filterTofu: true,
    sealRedlight: true,
    hybridPq: true,
    stegoVet: true,
    roundTable: true,
    glassesHud: true,
  );

  /// Pre-patch cabinet (used by the detector to name what got fixed).
  static const legacy = CabinetPolicy();

  CabinetPolicy copyWith({
    bool? v1Stego,
    bool? autoDensity,
    bool? chromeUsesRealSeed,
    bool? phosphorUsesMixer,
    bool? persistCoverPinGate,
    bool? v2Session,
    bool? filterTofu,
    bool? sealRedlight,
    bool? hybridPq,
    bool? stegoVet,
    bool? roundTable,
    bool? glassesHud,
  }) =>
      CabinetPolicy(
        v1Stego: v1Stego ?? this.v1Stego,
        autoDensity: autoDensity ?? this.autoDensity,
        chromeUsesRealSeed: chromeUsesRealSeed ?? this.chromeUsesRealSeed,
        phosphorUsesMixer: phosphorUsesMixer ?? this.phosphorUsesMixer,
        persistCoverPinGate: persistCoverPinGate ?? this.persistCoverPinGate,
        v2Session: v2Session ?? this.v2Session,
        filterTofu: filterTofu ?? this.filterTofu,
        sealRedlight: sealRedlight ?? this.sealRedlight,
        hybridPq: hybridPq ?? this.hybridPq,
        stegoVet: stegoVet ?? this.stegoVet,
        roundTable: roundTable ?? this.roundTable,
        glassesHud: glassesHud ?? this.glassesHud,
      );

  /// Stable wire form. Goes into the patch-ledger MAC so a Hive edit that
  /// flips a flag after the fact breaks the chain.
  String get canonical => [
        'stego=${v1Stego ? 1 : 0}',
        'density=${autoDensity ? 1 : 0}',
        'chrome=${chromeUsesRealSeed ? 1 : 0}',
        'mixer=${phosphorUsesMixer ? 1 : 0}',
        'pingate=${persistCoverPinGate ? 1 : 0}',
        'v2=${v2Session ? 1 : 0}',
        'tofu=${filterTofu ? 1 : 0}',
        'redlight=${sealRedlight ? 1 : 0}',
        'pq=${hybridPq ? 1 : 0}',
        'vet=${stegoVet ? 1 : 0}',
        'table=${roundTable ? 1 : 0}',
        'glasses=${glassesHud ? 1 : 0}',
      ].join(';');

  bool get isWoven => canonical == woven.canonical;

  @override
  bool operator ==(Object other) =>
      other is CabinetPolicy && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;
}
