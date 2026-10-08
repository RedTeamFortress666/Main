/// Expected SHA-256 digests and display labels for bundled flasher assets.
///
/// Digests are hex lowercase. [materializeVerified] refuses to proceed on mismatch.
class BundledAsset {
  const BundledAsset({
    required this.assetPath,
    required this.fileName,
    required this.sha256,
    required this.label,
    this.version = '',
    this.expectedMaxBytes,
  });

  final String assetPath;
  final String fileName;
  final String sha256;
  final String label;
  final String version;

  /// Soft warning threshold (e.g. classic CYD 4 MiB flash).
  final int? expectedMaxBytes;
}

class AssetIntegrity {
  AssetIntegrity._();

  static const cydBin = BundledAsset(
    assetPath: 'assets/firmware/polybius-cyd.bin',
    fileName: 'polybius-cyd.bin',
    sha256:
        '627ac98908dd772bad28a54104a9ab5562a1101e0b1127e25917b1020e7d76d2',
    label: 'CYD / ESP32 full image',
    version: 'cyd-full@0x0',
    expectedMaxBytes: 4 * 1024 * 1024,
  );

  static const tdeckBin = BundledAsset(
    assetPath: 'assets/firmware/polybius-tdeck.bin',
    fileName: 'polybius-tdeck.bin',
    sha256:
        'e40cf9add9f30ab2146933a69a251c82db81e77e4830c8dfed8c3b1f2e8004de',
    label: 'LilyGO T-Deck full image',
    version: 'tdeck-s3@0x0',
    expectedMaxBytes: 16 * 1024 * 1024,
  );

  static const r36sZip = BundledAsset(
    assetPath: 'assets/r36s/polybius-r36s-port.zip',
    fileName: 'polybius-r36s-port.zip',
    sha256:
        '58f7ae8a90f4fc0d74e51c0931949cd5e698a9f62663c4d65c777978765e2493',
    label: 'R36S PortMaster zip',
    version: 'r36s-port-1.0',
  );

  static const portalApk = BundledAsset(
    assetPath: 'assets/apks/polybius-v1-stable-hq-android-arm64.apk',
    fileName: 'polybius-v1-stable-hq-android-arm64.apk',
    sha256:
        'da19a6650c5536d9bec08528b4b054ceaa273ffd420a53c3334778aaa8331797',
    label: 'PØLYBÎŪS PORTAL',
    version: 'v1-stable-hq',
  );

  static const userApk = BundledAsset(
    assetPath: 'assets/apks/polybius-v1-stable-user-android-arm64.apk',
    fileName: 'polybius-v1-stable-user-android-arm64.apk',
    sha256:
        'b80aa0d3a5be89d7388135ede9193a82fc92cb58a92d4262c9815fc0ba27f294',
    label: 'PØLYBÎŪS V.1 USER',
    version: 'v1-stable-user',
  );

  static const darthApk = BundledAsset(
    assetPath: 'assets/apks/darth-cherry-1.0.2-android-arm64.apk',
    fileName: 'darth-cherry-1.0.2-android-arm64.apk',
    sha256:
        'b242a04ba6696ad2d4e354365319f4aa666718edf68af05034d7f3b00cca4146',
    label: 'DARTH CHERRY',
    version: '1.0.2',
  );

  static const all = <BundledAsset>[
    cydBin,
    tdeckBin,
    r36sZip,
    portalApk,
    userApk,
    darthApk,
  ];

  static BundledAsset? byAssetPath(String assetPath) {
    for (final a in all) {
      if (a.assetPath == assetPath) return a;
    }
    return null;
  }

  static BundledAsset? byFileName(String fileName) {
    for (final a in all) {
      if (a.fileName == fileName) return a;
    }
    return null;
  }
}
