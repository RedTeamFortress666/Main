import 'dart:convert';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';

/// Ed25519 signature verification for invite tokens and update payloads.
///
/// The app embeds only the PUBLIC key, so it can *verify* that a token or
/// update was signed by the holder of the matching private key, but cannot
/// forge one. Devs mint signed tokens offline with `tool/polybius_sign.dart`.
///
/// SECURITY NOTE: this stops forged invite codes and tampered update payloads.
/// It does NOT stop someone who controls the binary from patching the verifier
/// out — that is not achievable client-side (see BUILD.md).
class SignatureService {
  SignatureService({String? publicKeyB64})
      : publicKeyB64 = publicKeyB64 ?? kProjectSigningPublicKeyB64;

  /// BETA project verification key. Replace with your own from
  /// `dart run tool/polybius_keys.dart` before production; the matching
  /// private key must never ship in the app.
  static const String kProjectSigningPublicKeyB64 =
      'n3VtbToT9pexGOM0VIWl8gekiUQwVYEtSKE6y9XRS90=';

  final String publicKeyB64;
  static final Ed25519 _algorithm = Ed25519();

  Future<bool> verifyBytes(List<int> message, List<int> signature) async {
    try {
      final pub = SimplePublicKey(
        base64Decode(publicKeyB64),
        type: KeyPairType.ed25519,
      );
      return await _algorithm.verify(
        message,
        signature: Signature(signature, publicKey: pub),
      );
    } catch (_) {
      return false;
    }
  }

  /// Verifies a signed invite/license token against the trusted public key,
  /// also rejecting expired tokens.
  Future<bool> verifyToken(SignedToken token) async {
    if (token.isExpired) return false;
    return verifyBytes(utf8.encode(token.canonical), token.signature);
  }

  /// Verifies a detached signature over an update payload (signed over the
  /// SHA-256 digest so large payloads stay cheap).
  Future<bool> verifyPayload(List<int> payload, List<int> signature) {
    final digest = hash.sha256.convert(payload).bytes;
    return verifyBytes(digest, signature);
  }

  // --- Offline signing (used by tooling / dev key-holders only) ---

  static Future<List<int>> signBytes(
      List<int> message, List<int> privateSeed) async {
    final kp = await _algorithm.newKeyPairFromSeed(privateSeed);
    final sig = await _algorithm.sign(message, keyPair: kp);
    return sig.bytes;
  }

  static Future<List<int>> signPayload(
      List<int> payload, List<int> privateSeed) {
    final digest = hash.sha256.convert(payload).bytes;
    return signBytes(digest, privateSeed);
  }
}

/// A signed invite / license token binding a game file number to an access
/// tier and expiry. Wire format is base64url(JSON) so it can be pasted or
/// stored alongside an SD/USB copy of the game.
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

  /// Canonical bytes that are signed/verified (order matters).
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
        expiresAt:
            e == 0 ? null : DateTime.fromMillisecondsSinceEpoch(e),
        signature: base64Decode(decoded['s'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Mints a signed token (offline dev tooling / key-holder use only).
  static Future<SignedToken> mint({
    required String fileNumber,
    required String tier,
    required List<int> privateSeed,
    DateTime? expiresAt,
  }) async {
    final issuedAt = DateTime.now();
    final unsigned = SignedToken(
      fileNumber: fileNumber,
      tier: tier,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      signature: const [],
    );
    final sig =
        await SignatureService.signBytes(utf8.encode(unsigned.canonical), privateSeed);
    return SignedToken(
      fileNumber: fileNumber,
      tier: tier,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      signature: sig,
    );
  }
}
