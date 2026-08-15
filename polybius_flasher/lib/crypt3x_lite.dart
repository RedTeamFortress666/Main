/// Official CRYPT3X OS lite image catalog.
///
/// The 8 GiB GPT image cannot ship inside the APK. The flasher stages a
/// user-picked `.img` or `.img.zip` onto a USB stick / SAF tree and verifies
/// SHA-256 against this table. Host `dd` is [tool/flash_crypt3x_lite.sh].
class Crypt3xLiteCatalog {
  Crypt3xLiteCatalog._();

  static const lunch = 'lineage_r36s_crypt3x_lite-userdebug';
  static const packageDir = 'CRYPT3X_OS_LITE';
  static const readyMarker = 'CRYPT3X_LITE_READY.txt';

  static const fileName =
      'lineage-18.1-20260815-1244-r36s-crypt3x-lite.img';
  static const zipFileName =
      'lineage-18.1-20260815-1244-r36s-crypt3x-lite.img.zip';

  static const sha256 =
      'ece3a41fe3d5fed083c788a75cb912dc5c7013af9be26f52d7b4ecb94b95abcc';
  static const zipSha256 =
      '67493055e6bfad6a3c14b40b2723d19550eef99fde16cc23bf0250fdd7b61b38';

  /// Packed GPT image size (8 GiB).
  static const bytes = 8589934592;

  /// Compressed sidecar produced by `mkimg_lite.sh`.
  static const zipBytes = 965250113;

  static const displaySize = '8.0 GiB';
  static const zipDisplaySize = '921 MiB';
  static const label = 'CRYPT3X OS LITE';
  static const version = '20260815-1244';

  /// FAT32 max file size. Raw `.img` needs exFAT (or a PC `dd`).
  static const fat32MaxBytes = 4294967295;

  static const flashHint =
      'sudo dd if=lineage-18.1-20260815-1244-r36s-crypt3x-lite.img '
      'of=/dev/sdX bs=4M status=progress conv=fsync';

  static bool looksLikeZip(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.zip') || lower.endsWith('.img.zip');
  }

  static bool looksLikeImg(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.img') && !looksLikeZip(name);
  }

  static String? expectedSha256For(String name, {int? size}) {
    if (looksLikeZip(name) || size == zipBytes) return zipSha256;
    if (looksLikeImg(name) || size == bytes) return sha256;
    return null;
  }

  static int? expectedBytesFor(String name) {
    if (looksLikeZip(name)) return zipBytes;
    if (looksLikeImg(name)) return bytes;
    return null;
  }

  static String destFileNameFor(String name) {
    if (looksLikeZip(name)) return zipFileName;
    if (looksLikeImg(name)) return fileName;
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return safe.isEmpty ? fileName : safe;
  }
}
