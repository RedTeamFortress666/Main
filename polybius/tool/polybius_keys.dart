// Generates an Ed25519 signing key pair for PØLYBĪUS.
//
//   dart run tool/polybius_keys.dart
//
// Paste the PUBLIC key into `kProjectSigningPublicKeyB64` in
// lib/core/crypto/signature_service.dart. Keep the PRIVATE key secret — it is
// used offline by tool/polybius_sign.dart to mint signed invite tokens and
// update manifests. NEVER commit the private key.
import 'package:cryptography/cryptography.dart';
import 'dart:convert';

Future<void> main() async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final priv = await keyPair.extractPrivateKeyBytes();
  final pub = await keyPair.extractPublicKey();

  // ignore: avoid_print
  print('PUBLIC  (embed in app):  ${base64Encode(pub.bytes)}');
  // ignore: avoid_print
  print('PRIVATE (keep secret!):  ${base64Encode(priv)}');
}
