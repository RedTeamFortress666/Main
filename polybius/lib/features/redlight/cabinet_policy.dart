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

  /// Interwoven default — the patcher is the boot path, not a later click.
  static const woven = CabinetPolicy(
    v1Stego: false,
    autoDensity: true,
    chromeUsesRealSeed: true,
    phosphorUsesMixer: true,
    persistCoverPinGate: true,
    v2Session: true,
    filterTofu: true,
  );

  /// Pre-patch cabinet (used by the detector to name what got fixed).
  static const legacy = CabinetPolicy();
}
