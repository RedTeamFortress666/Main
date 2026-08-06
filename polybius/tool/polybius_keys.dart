// Generates an RSA-4096 signing key pair for PØLYBĪUS.
//
//   dart run tool/polybius_keys.dart
//
// Prints the PUBLIC modulus (base64) to paste into
// `kProjectRsaModulusB64` in lib/core/crypto/signature_service.dart, and writes
// the PRIVATE key params to tool/rsa_private.json (gitignored). The private
// file is used offline by tool/polybius_sign.dart to mint signed invite
// tokens. NEVER commit tool/rsa_private.json.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

String _b64(BigInt v) {
  final bytes = <int>[];
  while (v > BigInt.zero) {
    bytes.add((v & BigInt.from(0xff)).toInt());
    v = v >> 8;
  }
  return base64Encode(bytes.reversed.toList());
}

void main() {
  final rng = FortunaRandom();
  final r = Random.secure();
  rng.seed(KeyParameter(
      Uint8List.fromList(List<int>.generate(32, (_) => r.nextInt(256)))));
  final gen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.from(65537), 4096, 64),
      rng,
    ));
  final pair = gen.generateKeyPair();
  final pub = pair.publicKey as RSAPublicKey;
  final priv = pair.privateKey as RSAPrivateKey;

  // ignore: avoid_print
  print('PUBLIC modulus (embed in app): ${_b64(pub.modulus!)}');
  File('tool/rsa_private.json').writeAsStringSync(jsonEncode({
    'n': _b64(priv.modulus!),
    'd': _b64(priv.privateExponent!),
    'p': _b64(priv.p!),
    'q': _b64(priv.q!),
  }));
  // ignore: avoid_print
  print('Wrote tool/rsa_private.json (keep secret, never commit).');
}
