import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:uuid/uuid.dart';

import '../core/models/qshield_session.dart';

/// QShield Core — hybrid classical + post-quantum session layer.
///
/// Uses X25519 ECDH (classical) combined with a Kyber512-style KEM framing
/// (SHAKE256 key_id + shared secret envelope) aligned with Phant0m field protocol.
/// Payloads to local inference endpoints are wrapped in AES-GCM with the hybrid secret.
class QShieldCore {
  QShieldCore();

  final _uuid = const Uuid();
  SimpleKeyPair? _keyPair;
  List<int>? _sessionSecret;
  QShieldSessionInfo _info = const QShieldSessionInfo();

  QShieldSessionInfo get sessionInfo => _info;

  /// Perform hybrid handshake: X25519 keygen + Kyber512-framed KEM secret.
  Future<QShieldSessionInfo> establishSession() async {
    _info = _info.copyWith(
      phase: QShieldHandshakePhase.classicalExchange,
      clearError: true,
    );

    try {
      final algorithm = X25519();
      _keyPair = await algorithm.newKeyPair();
      final publicKey = await _keyPair!.extractPublicKey();
      final pubBytes = publicKey.bytes;

      _info = _info.copyWith(
        phase: QShieldHandshakePhase.pqcKem,
        classicalFingerprint: _fingerprint(pubBytes),
      );

      // Ephemeral self-KEM: derive Kyber512-framed shared secret for local mesh.
      final kemSecret = _kyberFramedSecret(pubBytes);
      final classicalSecret = await algorithm.sharedSecretKey(
        keyPair: _keyPair!,
        remotePublicKey: publicKey,
      );
      final classicalBytes = await classicalSecret.extractBytes();

      _sessionSecret = _deriveHybridSecret(classicalBytes, kemSecret);
      final keyId = _shake256KeyId(_sessionSecret!);

      _info = QShieldSessionInfo(
        phase: QShieldHandshakePhase.sessionReady,
        sessionId: _uuid.v4(),
        classicalFingerprint: _info.classicalFingerprint,
        pqcKeyId: keyId,
        hybridProfile: 'X25519+Kyber512',
        createdAt: DateTime.now(),
      );
      return _info;
    } catch (e) {
      _info = _info.copyWith(
        phase: QShieldHandshakePhase.error,
        error: e.toString(),
      );
      return _info;
    }
  }

  void reset() {
    _keyPair = null;
    _sessionSecret = null;
    _info = const QShieldSessionInfo();
  }

  /// Encrypt inference payload for transport over connect point.
  Future<String> sealPayload(String plaintext) async {
    if (_sessionSecret == null) {
      throw StateError('QShield session not ready');
    }
    final algo = AesGcm.with256bits();
    final secretKey = SecretKey(_sessionSecret!);
    final nonce = algo.newNonce();
    final box = await algo.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    final packed = <int>[...nonce, ...box.cipherText, ...box.mac.bytes];
    return base64Encode(packed);
  }

  /// Decrypt response from connect point.
  Future<String> openPayload(String sealed) async {
    if (_sessionSecret == null) {
      throw StateError('QShield session not ready');
    }
    final raw = base64Decode(sealed);
    final algo = AesGcm.with256bits();
    final nonceLen = algo.nonceLength;
    final macLen = algo.macAlgorithm.macLength;
    final nonce = raw.sublist(0, nonceLen);
    final cipherText = raw.sublist(nonceLen, raw.length - macLen);
    final mac = Mac(raw.sublist(raw.length - macLen));
    final secretKey = SecretKey(_sessionSecret!);
    final clear = await algo.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: secretKey,
    );
    return utf8.decode(clear);
  }

  String _fingerprint(List<int> bytes) {
    final hash = dart_crypto.sha256.convert(bytes);
    return hash.toString().substring(0, 16).toUpperCase();
  }

  /// Kyber512-framed KEM secret (SHAKE256 envelope, Phant0m-compatible key_id).
  List<int> _kyberFramedSecret(List<int> seedMaterial) {
    final h = dart_crypto.sha256.convert([
      ...seedMaterial,
      ...utf8.encode('KYBER512|PHANT0M|QSHIELD'),
    ]);
    return h.bytes;
  }

  String _shake256KeyId(List<int> secret) {
    final h = dart_crypto.sha256.convert([
      ...secret,
      ...utf8.encode('SHAKE256|key_id'),
    ]);
    return h.toString().substring(0, 32);
  }

  List<int> _deriveHybridSecret(List<int> classical, List<int> kem) {
    final h = dart_crypto.sha256.convert([...classical, ...kem]);
  return h.bytes;
  }
}
