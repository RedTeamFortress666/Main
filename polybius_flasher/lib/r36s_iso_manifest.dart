/// Required filenames for a PortMaster zip that the R36S will actually launch,
/// plus the CRYPT3X OS LITE GPT zip (full-card image).
///
/// A zip flashes / autoinstalls only if every [required] path is present.
/// The flasher UI prints these names so operators can audit a custom zip.
class R36IsoFile {
  const R36IsoFile({
    required this.path,
    required this.role,
    this.required = true,
  });

  final String path;
  final String role;
  final bool required;
}

class R36IsoDownload {
  const R36IsoDownload({
    required this.label,
    required this.fileName,
    required this.url,
  });

  final String label;
  final String fileName;
  final String url;
}

class R36IsoManifest {
  R36IsoManifest._();

  static const githubBranch =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/r36s-polybius-product-0346';

  static const packageFileName = 'polybius-r36s-port.zip';
  static const packageLabel = 'R36S PortMaster zip';
  static const version = 'r36s-port-1.0';
  static const bytes = 12096478;
  static const sha256 =
      '58f7ae8a90f4fc0d74e51c0931949cd5e698a9f62663c4d65c777978765e2493';

  /// Primary GitHub path (logged-in; repo is private).
  static const githubUrl = '$githubBranch/polybius/dist/$packageFileName';

  /// Backup GitHub path (same bytes, assets tree).
  static const githubBackupUrl =
      '$githubBranch/polybius_flasher/assets/r36s/$packageFileName';

  static const artifactName = 'polybius-r36s-port.zip';

  static const flasherApkFileName =
      'polybius-flasher-1.8.0-android-arm64.apk';
  static const flasherApkUrl =
      '$githubBranch/polybius/dist/$flasherApkFileName';
  static const flasherApkBackupUrl =
      '$githubBranch/polybius/dist/polybius-flasher-1.7.0-android-arm64.apk';

  /// Names the PortMaster zip must contain. Verify looks for Polybius.sh +
  /// polybius/; the rest are required for the Flutter Linux binary to start.
  static const portZipFiles = <R36IsoFile>[
    R36IsoFile(
      path: 'ports/Polybius.sh',
      role: 'PortMaster launcher (required)',
    ),
    R36IsoFile(
      path: 'ports/polybius/polybius',
      role: 'ARM64 game binary (required)',
    ),
    R36IsoFile(
      path: 'ports/polybius/polybius.gptk',
      role: 'Gamepad map (required)',
    ),
    R36IsoFile(
      path: 'ports/polybius/README.txt',
      role: 'On-device install notes',
    ),
    R36IsoFile(
      path: 'ports/polybius/lib/libapp.so',
      role: 'Flutter app library (required)',
    ),
    R36IsoFile(
      path: 'ports/polybius/lib/libflutter_linux_gtk.so',
      role: 'Flutter engine (required)',
    ),
    R36IsoFile(
      path: 'ports/polybius/lib/libaudioplayers_linux_plugin.so',
      role: 'Audio plugin',
    ),
    R36IsoFile(
      path: 'ports/polybius/lib/libgamepads_linux_plugin.so',
      role: 'Gamepad plugin',
    ),
    R36IsoFile(
      path: 'ports/polybius/lib/liburl_launcher_linux_plugin.so',
      role: 'URL launcher plugin',
    ),
    R36IsoFile(
      path: 'ports/polybius/lib/libflutter_secure_storage_linux_plugin.so',
      role: 'Secure storage plugin',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/icudtl.dat',
      role: 'ICU data (required)',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/AssetManifest.bin',
      role: 'Asset index',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/AssetManifest.bin.json',
      role: 'Asset index JSON',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/FontManifest.json',
      role: 'Font index',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/NativeAssetsManifest.json',
      role: 'Native asset index',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/version.json',
      role: 'Engine version stamp',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/NOTICES',
      role: 'License notices',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/NOTICES.Z',
      role: 'Compressed notices',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/fonts/MaterialIcons-Regular.otf',
      role: 'Material icons font',
    ),
    R36IsoFile(
      path:
          'ports/polybius/data/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
      role: 'Cupertino icons font',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/shaders/ink_sparkle.frag',
      role: 'Ink sparkle shader',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/shaders/stretch_effect.frag',
      role: 'Stretch shader',
    ),
    R36IsoFile(
      path: 'ports/polybius/data/flutter_assets/assets/audio/polybius_theme.wav',
      role: 'Theme audio',
    ),
  ];

  static const verifyMustExist = <String>[
    'ports/Polybius.sh',
    'ports/polybius/polybius',
    'ports/polybius/lib/libapp.so',
    'ports/polybius/lib/libflutter_linux_gtk.so',
  ];

  static const crypt3xKitFileName = 'CRYPT3X_OS_LITE-r36s-20260815.zip';
  static const crypt3xKitSha256 =
      'e79ac4225e702c3b5b5dc353198522be2141c2d6f20c8ec9df6f8cb548428f93';
  static const crypt3xImgFileName =
      'lineage-18.1-20260815-1244-r36s-crypt3x-lite.img';
  static const crypt3xImgSha256 =
      'ece3a41fe3d5fed083c788a75cb912dc5c7013af9be26f52d7b4ecb94b95abcc';

  static const crypt3xPartFiles = <String>[
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part00',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part01',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part02',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part03',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part04',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part05',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part06',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part07',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part08',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part09',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part10',
    'CRYPT3X_OS_LITE-r36s-20260815.zip.part11',
  ];

  static const downloads = <R36IsoDownload>[
    R36IsoDownload(
      label: 'Flasher APK 1.8.0 (this build)',
      fileName: flasherApkFileName,
      url: flasherApkUrl,
    ),
    R36IsoDownload(
      label: 'R36S PortMaster zip (primary)',
      fileName: packageFileName,
      url: githubUrl,
    ),
    R36IsoDownload(
      label: 'R36S PortMaster zip (backup path)',
      fileName: packageFileName,
      url: githubBackupUrl,
    ),
  ];

  static String checklistText() {
    final buf = StringBuffer()
      ..writeln('PØLYBÎŪS — files required in $packageFileName')
      ..writeln('SHA-256 $sha256')
      ..writeln('Verify must include: ${verifyMustExist.join(', ')}')
      ..writeln();
    for (final f in portZipFiles) {
      buf.writeln('${f.required ? "[REQ]" : "[opt]"} ${f.path}');
      buf.writeln('      ${f.role}');
    }
    buf
      ..writeln()
      ..writeln('Download (GitHub, logged-in):')
      ..writeln('  $githubUrl')
      ..writeln('Backup:')
      ..writeln('  $githubBackupUrl')
      ..writeln('  Bundled inside the flasher APK (no extra download).')
      ..writeln()
      ..writeln('CRYPT3X OS LITE full-card image (not PortMaster):')
      ..writeln('  $crypt3xKitFileName')
      ..writeln('  inner $crypt3xImgFileName')
      ..writeln('  assemble from ${crypt3xPartFiles.length} × 80 MiB parts')
      ..writeln('  flasher: PREPARE ETCHER / RUFUS KIT → CRYPT3X_ETCHER/');
    return buf.toString();
  }

  static String alternateFlashText() {
    return '''
IF THE PHONE FLASHER FAILS — R36S PortMaster zip
1. Copy $packageFileName onto a FAT32/exFAT stick or the R36S SD.
2. On the handheld file manager, unzip so you have:
     roms/ports/Polybius.sh
     roms/ports/polybius/
   (ArkOS/JELOS: roms/ports. Some ROCKNIX: roms2/ports. Some: EASYROMS/ports.)
3. PortMaster autoinstall: copy $packageFileName to
     roms/ports/autoinstall/   OR   PortMaster/autoinstall/
   then reboot or open PortMaster.
4. Launch Polybius from the Ports menu. Do not format the SD.

IF YOU WANT A FULL OS IMAGE INSTEAD (erases the card)
1. In the flasher: CRYPT3X OS LITE → PREPARE ETCHER / RUFUS KIT.
   Pick the folder with part00–part11, then the USB stick.
   That writes CRYPT3X_ETCHER/ with the assembled zip + ETCHER.txt + RUFUS.txt.
   Or on a PC: cat the 12 parts (tool/assemble-crypt3x-lite-zip.sh).
2. Unzip → $crypt3xImgFileName (8 GiB GPT, not a CD ISO).
3. Write with balenaEtcher, Raspberry Pi Imager, Rufus (DD mode), or:
     sudo dd if=$crypt3xImgFileName of=/dev/sdX bs=4M status=progress conv=fsync
4. Power off the R36S, insert the card in the OS slot, power on.

GitHub raw URLs 404 unless you are logged in (private repo).
''';
  }
}
