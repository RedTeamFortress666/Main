import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:polybius/core/crypto/hkdf.dart';

/// Hybrid sealed envelope for operator sync.
///
/// Live primitives:
///   * X25519 ephemeral ECDH (classic KEM)
///   * AES-256-GCM for the payload (NIST AES; there is no AES-512)
///
/// Post-quantum slot:
///   [PqKem] is an interface. This build does **not** ship an audited ML-KEM
///   (Kyber) implementation in Dart. When [pqKem] is null the PQ field is
///   empty and the key is HKDF(X25519). When a real ML-KEM is wired later,
///   the combiner is HKDF(X25519_ss || MLKEM_ss) — a standard hybrid, not
///   "uncrackable", and still bounded by implementation quality.
///
/// AES-256 vs "experimental larger variants": AES is defined for 128/192/256
/// bit keys. 256-bit Rijndael-with-bigger-blocks is not AES and has far less
/// analysis. If we ever want a second AEAD, XChaCha20-Poly1305 is the honest
/// alternative — not a fantasy AES-512.
class HybridEnvelope {
  HybridEnvelope({this.pqKem});

  static const magic = [0x50, 0x42, 0x48, 0x45]; // PBHE
  static const version = 1;
  static const flagHasPq = 0x01;

  final PqKem? pqKem;
  final _x25519 = X25519();
  final _aes = AesGcm.with256bits();

  Future<SimpleKeyPair> generateClassicKeyPair() => _x25519.newKeyPair();

  /// Seals [plaintext] to [peerClassicPublic] (32-byte X25519).
  Future<Uint8List> seal({
    required List<int> plaintext,
    required List<int> peerClassicPublic,
    List<int>? peerPqPublic,
    List<int> info = const [0x50, 0x42], // "PB"
  }) async {
    final ephemeral = await _x25519.newKeyPair();
    final ephPub = await ephemeral.extractPublicKey();
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        peerClassicPublic,
        type: KeyPairType.x25519,
      ),
    );
    final xBytes = await shared.extractBytes();

    var flags = 0;
    var pqCt = Uint8List(0);
    var pqSs = Uint8List(0);
    final kem = pqKem;
    if (kem != null && peerPqPublic != null) {
      final enc = await kem.encaps(Uint8List.fromList(peerPqPublic));
      flags |= flagHasPq;
      pqCt = enc.ciphertext;
      pqSs = enc.sharedSecret;
    }

    final keyBytes = hkdfSha256(
      ikm: [...xBytes, ...pqSs],
      salt: ephPub.bytes,
      info: info,
      length: 32,
    );
    final nonce = _randomBytes(12);
    final box = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    );

    final out = BytesBuilder();
    out.add(magic);
    out.addByte(version);
    out.addByte(flags);
    out.add(ephPub.bytes);
    out.add(_u16(pqCt.length));
    out.add(pqCt);
    out.add(nonce);
    out.add(box.cipherText);
    out.add(box.mac.bytes);
    return out.toBytes();
  }

  Future<Uint8List> open({
    required List<int> wire,
    required SimpleKeyPair recipientClassic,
    List<int>? recipientPqSecret,
    List<int> info = const [0x50, 0x42],
  }) async {
    final data = Uint8List.fromList(wire);
    if (data.length < 4 + 1 + 1 + 32 + 2 + 12 + 16) {
      throw const FormatException('CABINET ENVELOPE TRUNCATED');
    }
    var o = 0;
    if (data[0] != magic[0] ||
        data[1] != magic[1] ||
        data[2] != magic[2] ||
        data[3] != magic[3]) {
      throw const FormatException('CABINET ENVELOPE MAGIC');
    }
    o = 4;
    final ver = data[o++];
    if (ver != version) {
      throw FormatException('CABINET ENVELOPE VERSION $ver');
    }
    final flags = data[o++];
    final ephPub = data.sublist(o, o + 32);
    o += 32;
    final pqLen = (data[o] << 8) | data[o + 1];
    o += 2;
    if (o + pqLen + 12 + 16 > data.length) {
      throw const FormatException('CABINET ENVELOPE PQ/CT');
    }
    final pqCt = data.sublist(o, o + pqLen);
    o += pqLen;
    final nonce = data.sublist(o, o + 12);
    o += 12;
    final rest = data.sublist(o);
    if (rest.length < 16) {
      throw const FormatException('CABINET ENVELOPE TAG');
    }
    final mac = rest.sublist(rest.length - 16);
    final cipherText = rest.sublist(0, rest.length - 16);

    final shared = await _x25519.sharedSecretKey(
      keyPair: recipientClassic,
      remotePublicKey: SimplePublicKey(ephPub, type: KeyPairType.x25519),
    );
    final xBytes = await shared.extractBytes();

    var pqSs = Uint8List(0);
    final kem = pqKem;
    if (flags & flagHasPq != 0) {
      if (kem == null || recipientPqSecret == null) {
        throw const FormatException('CABINET PQ SLOT UNAVAILABLE');
      }
      pqSs = await kem.decaps(Uint8List.fromList(recipientPqSecret), pqCt);
    }

    final keyBytes = hkdfSha256(
      ikm: [...xBytes, ...pqSs],
      salt: ephPub,
      info: info,
      length: 32,
    );
    final clear = await _aes.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(keyBytes),
    );
    return Uint8List.fromList(clear);
  }

  static Uint8List _u16(int n) => Uint8List.fromList([(n >> 8) & 0xff, n & 0xff]);

  static Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rng.nextInt(256)));
  }
}

/// Optional post-quantum KEM. Do not claim NIST ML-KEM until this is an
/// audited implementation with known-answer tests.
abstract class PqKem {
  String get id;

  Future<PqEncapsulation> encaps(Uint8List peerPublic);

  Future<Uint8List> decaps(Uint8List secretKey, Uint8List ciphertext);
}

class PqEncapsulation {
  const PqEncapsulation({
    required this.ciphertext,
    required this.sharedSecret,
  });

  final Uint8List ciphertext;
  final Uint8List sharedSecret;
}

/// Debug helper: encode a public key as base64url for QR / sidecar config.
String encodeClassicPublic(List<int> bytes) => base64Url.encode(bytes);
