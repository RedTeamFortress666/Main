/// Official CRYPT3X OS lite image catalog.
///
/// The 8 GiB GPT image cannot ship inside the APK. The flasher either stages a
/// user-picked `.img` / `.img.zip`, or concatenates the twelve 80 MiB parts
/// into `CRYPT3X_ETCHER/` for balenaEtcher / Rufus. Host `dd` is
/// [tool/flash_crypt3x_lite.sh].
class Crypt3xLitePart {
  const Crypt3xLitePart({
    required this.index,
    required this.fileName,
    required this.altFileName,
    required this.bytes,
    required this.sha256,
    this.altSha256,
    this.altBytes,
  });

  final int index;
  final String fileName;
  final String altFileName;
  final int bytes;
  final String sha256;
  final String? altSha256;
  final int? altBytes;

  String get tag => 'part${index.toString().padLeft(2, '0')}';
}

class Crypt3xLiteDownload {
  const Crypt3xLiteDownload({
    required this.label,
    required this.fileName,
    required this.where,
    this.sha256,
    this.required = true,
  });

  final String label;
  final String fileName;
  final String where;
  final String? sha256;
  final bool required;
}

class Crypt3xLiteCatalog {
  Crypt3xLiteCatalog._();

  static const lunch = 'lineage_r36s_crypt3x_lite-userdebug';
  static const packageDir = 'CRYPT3X_OS_LITE';
  static const etcherFolder = 'CRYPT3X_ETCHER';
  static const readyMarker = 'CRYPT3X_LITE_READY.txt';
  static const etcherReadyMarker = 'CRYPT3X_ETCHER_READY.txt';

  static const fileName =
      'lineage-18.1-20260815-1244-r36s-crypt3x-lite.img';
  static const zipFileName =
      'lineage-18.1-20260815-1244-r36s-crypt3x-lite.img.zip';
  static const kitFileName = 'CRYPT3X_OS_LITE-r36s-20260815.zip';
  static const sumsFileName = 'CRYPT3X_OS_LITE-r36s-20260815.zip.SHA256SUMS';

  static const sha256 =
      'ece3a41fe3d5fed083c788a75cb912dc5c7013af9be26f52d7b4ecb94b95abcc';
  static const zipSha256 =
      '67493055e6bfad6a3c14b40b2723d19550eef99fde16cc23bf0250fdd7b61b38';
  static const kitSha256 =
      'e79ac4225e702c3b5b5dc353198522be2141c2d6f20c8ec9df6f8cb548428f93';

  /// Packed GPT image size (8 GiB).
  static const bytes = 8589934592;

  /// Official img-only zip from `mkimg_lite.sh`.
  static const zipBytes = 965250113;

  /// Kit zip (img + FLASH_R36S.txt + SHA256SUMS.txt). Concat of part00–part11.
  static const kitBytes = 965251465;

  static const displaySize = '8.0 GiB';
  static const zipDisplaySize = '921 MiB';
  static const label = 'CRYPT3X OS LITE';
  static const version = '20260815-1244';

  /// FAT32 max file size. Raw `.img` needs exFAT (or a PC `dd`).
  static const fat32MaxBytes = 4294967295;

  static const partBytes = 83886080;

  static const flashHint =
      'sudo dd if=lineage-18.1-20260815-1244-r36s-crypt3x-lite.img '
      'of=/dev/sdX bs=4M status=progress conv=fsync';

  static const parts = <Crypt3xLitePart>[
    Crypt3xLitePart(
      index: 0,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part00',
      altFileName: 'crypt3x_lite_img_zip.part00',
      bytes: 83886080,
      sha256:
          '81160e23e4ed231f7a7c91b63bbc39bf322d35d519f8b3c11f6106a31f3d4b54',
    ),
    Crypt3xLitePart(
      index: 1,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part01',
      altFileName: 'crypt3x_lite_img_zip.part01',
      bytes: 83886080,
      sha256:
          'c0d6dc5e7f0015d04d63827ede18edbd8f342fc40d694f71660cf18f254475a0',
    ),
    Crypt3xLitePart(
      index: 2,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part02',
      altFileName: 'crypt3x_lite_img_zip.part02',
      bytes: 83886080,
      sha256:
          '6a245290b75f14c64ac95fc789647b6f997adfcbc908ffb143233fcc9ba0fcce',
    ),
    Crypt3xLitePart(
      index: 3,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part03',
      altFileName: 'crypt3x_lite_img_zip.part03',
      bytes: 83886080,
      sha256:
          '1df4fa8cd27a353700d5d0f621edf5ef851c65f2f82eaf70f5f42ffa22f87a7f',
    ),
    Crypt3xLitePart(
      index: 4,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part04',
      altFileName: 'crypt3x_lite_img_zip.part04',
      bytes: 83886080,
      sha256:
          '49a3183015b1ab1576531c13599712dc0f143b1c70e5c49faabb239773756d55',
    ),
    Crypt3xLitePart(
      index: 5,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part05',
      altFileName: 'crypt3x_lite_img_zip.part05',
      bytes: 83886080,
      sha256:
          'f4aa5a1aab9455e0b3078335aa63ba63dcfb4fa8b2117aa732f3c157aba66f45',
    ),
    Crypt3xLitePart(
      index: 6,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part06',
      altFileName: 'crypt3x_lite_img_zip.part06',
      bytes: 83886080,
      sha256:
          'f8f8904b885453b67415fb4515f1d4fa04309f8d5212140fdbcb758dc7255f3d',
    ),
    Crypt3xLitePart(
      index: 7,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part07',
      altFileName: 'crypt3x_lite_img_zip.part07',
      bytes: 83886080,
      sha256:
          'a85cb0a426eb8b45b0a074ebb6b98bc8c0f7e41665479ac24417464848bee4c2',
    ),
    Crypt3xLitePart(
      index: 8,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part08',
      altFileName: 'crypt3x_lite_img_zip.part08',
      bytes: 83886080,
      sha256:
          '65ca8ad3608734eb0169e26b94f74845135126867e294ef3309ce4157f1aa176',
    ),
    Crypt3xLitePart(
      index: 9,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part09',
      altFileName: 'crypt3x_lite_img_zip.part09',
      bytes: 83886080,
      sha256:
          '3b22e9f942724ff9d3d5ac117ac9526e4422b9d1fdb91c02383d1a5a782c5634',
    ),
    Crypt3xLitePart(
      index: 10,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part10',
      altFileName: 'crypt3x_lite_img_zip.part10',
      bytes: 83886080,
      sha256:
          '1d423c9f1d7bb2096ec7468114f62ad15b269eef6147d20c05fc85e5a0b7443d',
    ),
    Crypt3xLitePart(
      index: 11,
      fileName: 'CRYPT3X_OS_LITE-r36s-20260815.zip.part11',
      altFileName: 'crypt3x_lite_img_zip.part11',
      bytes: 42504585,
      sha256:
          'd609f1a9d04646b4ea14aba8529588ff2c3a311350b9d4f3c494f8878a7b8294',
      altSha256:
          '906366f5252ca2510f26abbaa1c23b8e243b917719fd544808c009473ea89c9e',
      altBytes: 42503233,
    ),
  ];

  static const githubBranch =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346';

  static const flasherApkFileName =
      'polybius-flasher-1.8.0-android-arm64.apk';
  static const flasherApkUrl =
      '$githubBranch/polybius/dist/$flasherApkFileName';
  static const flasherApkBackupFileName =
      'polybius-flasher-1.7.0-android-arm64.apk';

  /// Everything an operator needs for beta OS testing on an R36S.
  static const betaDownloads = <Crypt3xLiteDownload>[
    Crypt3xLiteDownload(
      label: 'PØLYBÎŪS FLASHER APK 1.8.0',
      fileName: flasherApkFileName,
      where: 'GitHub (logged-in) $flasherApkUrl · also Cursor artifact',
    ),
    Crypt3xLiteDownload(
      label: 'Flasher APK 1.7.0 backup',
      fileName: flasherApkBackupFileName,
      where:
          '$githubBranch/polybius/dist/$flasherApkBackupFileName',
      required: false,
    ),
    Crypt3xLiteDownload(
      label: 'Kit SHA-256 table',
      fileName: sumsFileName,
      where: 'Cursor artifact (not GitHub — 921 MiB zip is split)',
      sha256: kitSha256,
    ),
    Crypt3xLiteDownload(
      label: 'Flash instructions',
      fileName: 'FLASH_R36S.txt',
      where:
          'Repo device_r36s_polybius/FLASH_R36S.txt · also Cursor artifact CRYPT3X_OS_LITE_R36S_FLASH.txt',
      required: false,
    ),
    Crypt3xLiteDownload(
      label: 'Assemble script (PC)',
      fileName: 'assemble-crypt3x-lite-zip.sh',
      where: 'Repo polybius_flasher/tool/',
      required: false,
    ),
    Crypt3xLiteDownload(
      label: 'R36S PortMaster zip (ArkOS port — not the OS image)',
      fileName: 'polybius-r36s-port.zip',
      where:
          '$githubBranch/polybius/dist/polybius-r36s-port.zip · bundled in the flasher APK',
      sha256:
          '58f7ae8a90f4fc0d74e51c0931949cd5e698a9f62663c4d65c777978765e2493',
      required: false,
    ),
  ];

  static List<Crypt3xLiteDownload> get allRequiredDownloads {
    return [
      ...betaDownloads.where((d) => d.required && d.fileName != sumsFileName),
      ...parts.map(
        (p) => Crypt3xLiteDownload(
          label: 'OS zip ${p.tag}',
          fileName: p.fileName,
          where:
              'Cursor artifact. Alternate name ${p.altFileName} (part11 SHA differs on the img-only zip).',
          sha256: p.sha256,
        ),
      ),
      betaDownloads.firstWhere((d) => d.fileName == sumsFileName),
    ];
  }

  static bool looksLikeZip(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.zip') || lower.endsWith('.img.zip');
  }

  static bool looksLikeImg(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.img') && !looksLikeZip(name);
  }

  static bool looksLikeKitZip(String name) {
    final lower = name.toLowerCase();
    return lower.contains('crypt3x_os_lite-r36s') && looksLikeZip(name);
  }

  static String? expectedSha256For(String name, {int? size}) {
    if (size == kitBytes || looksLikeKitZip(name)) return kitSha256;
    if (size == zipBytes) return zipSha256;
    if (looksLikeZip(name)) return zipSha256;
    if (looksLikeImg(name) || size == bytes) return sha256;
    return null;
  }

  static int? expectedBytesFor(String name) {
    if (looksLikeKitZip(name)) return kitBytes;
    if (looksLikeZip(name)) return zipBytes;
    if (looksLikeImg(name)) return bytes;
    return null;
  }

  static String destFileNameFor(String name) {
    if (looksLikeKitZip(name)) return kitFileName;
    if (looksLikeZip(name)) return zipFileName;
    if (looksLikeImg(name)) return fileName;
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safe.isEmpty ? fileName : safe;
  }

  /// SHA-256 of the concatenated parts → dest zip name for Etcher.
  static String? etcherDestNameForSha256(String hex) {
    final h = hex.toLowerCase();
    if (h == kitSha256) return kitFileName;
    if (h == zipSha256) return zipFileName;
    return null;
  }

  static String etcherInstructions(String zipName) => '''
CRYPT3X OS LITE — balenaEtcher / Raspberry Pi Imager
====================================================

This folder was assembled by PØLYBÎŪS FLASHER from part00–part11.

1. Eject this USB stick and plug it into a PC.
2. Open balenaEtcher (or Raspberry Pi Imager).
3. Flash from file: $zipName
   (Etcher accepts a zip that contains a .img. If it refuses extra
   .txt files inside the kit zip, unzip first and select $fileName.)
4. Select the R36S microSD (32 GB or larger). Confirm.
5. Flash. Eject. Power the handheld OFF, seat the card in the OS slot,
   power on. First boot can take a few minutes.

Do not copy $fileName onto a formatted card. That is not a flash.
This erases the entire microSD.
''';

  static String rufusInstructions(String zipName) => '''
CRYPT3X OS LITE — Rufus (Windows)
=================================

1. Copy $zipName off this stick onto a PC disk with >9 GiB free.
2. Unzip. You need the raw $fileName (8 GiB).
   FAT32 cannot store that file (4 GiB cap) — unzip onto NTFS or exFAT.
3. Open Rufus. Select the microSD.
4. Boot selection: Disk or ISO image → the .img file.
5. Image mode: DD Image (not ISO). Write. Eject.

Do not use ISO mode. This is a GPT disk image, not a CD ISO.
''';

  static String flashInstructions(String zipName) => '''
# CRYPT3X OS LITE — flash the R36S SD
# WARNING: this erases the target device.

unzip -o $zipName
sudo dd if=$fileName of=/dev/sdX bs=4M status=progress conv=fsync
sync

Or from the repo:
  polybius_flasher/tool/flash_crypt3x_lite.sh /dev/sdX

balenaEtcher / Raspberry Pi Imager: select $zipName or $fileName.
Rufus: $fileName in DD Image mode.
''';
}
