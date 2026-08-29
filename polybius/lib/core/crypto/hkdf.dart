import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// HKDF-SHA256 (RFC 5869). Used to mix X25519 (and optional PQ) shares into
/// AES-256 keys without inventing a homemade KDF.
Uint8List hkdfSha256({
  required List<int> ikm,
  required List<int> info,
  List<int>? salt,
  int length = 32,
}) {
  if (length <= 0 || length > 255 * 32) {
    throw ArgumentError.value(length, 'length', 'HKDF output out of range');
  }
  final prk = Hmac(sha256, salt ?? Uint8List(32)).convert(ikm).bytes;
  final okm = <int>[];
  var previous = <int>[];
  var counter = 1;
  while (okm.length < length) {
    final block = Hmac(sha256, prk).convert([
      ...previous,
      ...info,
      counter,
    ]).bytes;
    okm.addAll(block);
    previous = block;
    counter++;
  }
  return Uint8List.fromList(okm.sublist(0, length));
}

/// HMAC-SHA256 convenience for session derangements and pool shuffles.
List<int> hmacSha256(List<int> key, List<int> message) =>
    Hmac(sha256, key).convert(message).bytes;
