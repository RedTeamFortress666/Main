import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Session key for Cherry animated QR. Only `PBK-` keys are accepted so a
/// generic scanner cannot treat the stream as a session.
class SessionBinaryKey {
  SessionBinaryKey._();

  static const prefix = 'PBK-';

  /// 32 secure random bytes as `PBK-` + base64url.
  static String create() {
    final rng = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => rng.nextInt(256)),
    );
    return '$prefix${base64Url.encode(bytes)}';
  }

  static bool isValid(String raw) {
    try {
      decode(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Uint8List decode(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(prefix)) {
      throw const FormatException('not a polybius keyboard key');
    }
    final body = trimmed.substring(prefix.length);
    final bytes = base64Url.decode(body);
    if (bytes.length != 32) {
      throw const FormatException('wrong key length');
    }
    return Uint8List.fromList(bytes);
  }
}
