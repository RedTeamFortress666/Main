import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// RSA (PKCS#1 v1.5, SHA-256) signature verification for invite tokens and
/// update payloads.
///
/// The app embeds only the project's RSA-4096 PUBLIC modulus (extracted from
/// the developer's OpenPGP key), so it can *verify* that a token/update was
/// signed by the holder of the matching private key, but cannot forge one.
///
/// SECURITY NOTE: this stops forged invite codes and tampered update payloads.
/// It does NOT stop someone who controls the binary from patching the verifier
/// out — that is not achievable client-side (see BUILD.md). Cipher access is
/// never a compiled code; the portal passphrase is hashed on the account.
class SignatureService {
  SignatureService({String? modulusB64})
      : modulusB64 = (modulusB64 == null || modulusB64.isEmpty)
            ? kProjectRsaModulusB64
            : modulusB64;

  /// Project verification key: RSA-4096 modulus (base64, big-endian) of the
  /// developer's OpenPGP key `0x24D2A8CD`'s replacement RSA key. Public only.
  static const String kProjectRsaModulusB64 =
      'yDGKhJJQzjs3uyeupQT/XAMyjbzA7AWdOrHQy6FiKnvHNauUqReaHeo+Gp7EQCrnRantzXAmz8K8XNggY2QO/wOzVUwKRf+N36mzXpptJ8E+AxBldO9PyYek+31Df0kZRwqGBEjWFnoXXHEHqwok+R13f6uRkmrh5yOVL4hYlQNHCLkvOdv805HJmXSyYrdZp6XMpOXGSyXihgfjS48qmYv1K6+irBe8h88IVxECvghHYnuSatYNaQA0b1XPE2ystNsldgLpPYxlLY/iQ2aaJhmjWyjnGe0cLpDdMwYjhfu+6eKF1aoV0VOhE29cvz/oeVq/YkFPtEEIDPIPBhcd7vtfDh/Wl5SSBGGWHAjOjTIOleF8Ua/WBkAAmoOzD5r2GkoLYrqfp5ff/NI0C/hH2KT7b1VGGRcLka8ciw19jtDCQzGYgujWyigW+gxDouNIWwklYfmdWEzi3uOECYzjEPXmUs0/9FEDBaWQUrOlX7VWcQGMvun115TrN2NK2cyt14SCH0Qta5eZQzl6/T/IlKmbD89tcoYsH3ldJke0mDJ2yw1+degtCPLqhcGmxW2YxoF5xZd8IT79UkZ9GFOor8hmpPZHT918bIdd+xeIkw+xBvRlAAAEcRiVu98AILiTxtVmtBX6CzH4DBTmml/ueo+UaQ+lW9VIJZnCPDoGaAs=';

  static final BigInt kProjectRsaExponent = BigInt.from(65537);

  /// SHA-256 digest identifier (DER) for RSASigner.
  static const String _sha256Der = '0609608648016503040201';

  final String modulusB64;

  RSAPublicKey get _publicKey =>
      RSAPublicKey(_bytesToBigInt(base64Decode(modulusB64)), kProjectRsaExponent);

  bool verifyBytes(List<int> message, List<int> signature) {
    try {
      final signer = RSASigner(SHA256Digest(), _sha256Der)
        ..init(false, PublicKeyParameter<RSAPublicKey>(_publicKey));
      return signer.verifySignature(
        Uint8List.fromList(message),
        RSASignature(Uint8List.fromList(signature)),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyToken(SignedToken token) async {
    if (token.isExpired) return false;
    return verifyBytes(utf8.encode(token.canonical), token.signature);
  }

  Future<bool> verifyPayload(List<int> payload, List<int> signature) async =>
      verifyBytes(payload, signature);

  // --- Signing (offline dev key-holders / tooling / tests only) ---

  static List<int> signBytes(List<int> message, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), _sha256Der)
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return signer.generateSignature(Uint8List.fromList(message)).bytes;
  }

  static List<int> signPayload(List<int> payload, RSAPrivateKey privateKey) =>
      signBytes(payload, privateKey);

  static BigInt _bytesToBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }
}

/// A signed invite / license token binding a game file number to an access
/// tier and expiry. Wire format is base64url(JSON). Signatures are RSA
/// (PKCS#1 v1.5, SHA-256) over [canonical].
class SignedToken {
  const SignedToken({
    required this.fileNumber,
    required this.tier,
    required this.issuedAt,
    required this.signature,
    this.expiresAt,
  });

  final String fileNumber;
  final String tier;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final List<int> signature;

  String get canonical => [
        fileNumber,
        tier,
        issuedAt.millisecondsSinceEpoch,
        expiresAt?.millisecondsSinceEpoch ?? 0,
      ].join('|');

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String encode() {
    final json = {
      'f': fileNumber,
      't': tier,
      'i': issuedAt.millisecondsSinceEpoch,
      'e': expiresAt?.millisecondsSinceEpoch ?? 0,
      's': base64Encode(signature),
    };
    return base64Url.encode(utf8.encode(jsonEncode(json)));
  }

  static SignedToken? tryParse(String raw) {
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
          as Map<String, dynamic>;
      final e = decoded['e'] as int? ?? 0;
      return SignedToken(
        fileNumber: decoded['f'] as String,
        tier: decoded['t'] as String,
        issuedAt: DateTime.fromMillisecondsSinceEpoch(decoded['i'] as int),
        expiresAt: e == 0 ? null : DateTime.fromMillisecondsSinceEpoch(e),
        signature: base64Decode(decoded['s'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Mints a signed token (offline dev tooling / key-holder use only).
  static SignedToken mint({
    required String fileNumber,
    required String tier,
    required RSAPrivateKey privateKey,
    DateTime? expiresAt,
  }) {
    final issuedAt = DateTime.now();
    final unsigned = SignedToken(
      fileNumber: fileNumber,
      tier: tier,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      signature: const [],
    );
    final sig =
        SignatureService.signBytes(utf8.encode(unsigned.canonical), privateKey);
    return SignedToken(
      fileNumber: fileNumber,
      tier: tier,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      signature: sig,
    );
  }
}
