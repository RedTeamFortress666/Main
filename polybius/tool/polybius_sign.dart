// Offline signer for PØLYBĪUS. Reads the RSA private key from
// tool/rsa_private.json (produced by tool/polybius_keys.dart). Run on a trusted
// machine only; never commit rsa_private.json.
//
// Mint a signed invite/license token:
//   dart run tool/polybius_sign.dart token <fileNumber> <tier> [expiresInDays]
//
// Sign an update payload file (prints a detached base64 signature):
//   dart run tool/polybius_sign.dart payload <path>
import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/export.dart';
import 'package:polybius/core/crypto/signature_service.dart';

BigInt _fromB64(String s) {
  var v = BigInt.zero;
  for (final b in base64Decode(s)) {
    v = (v << 8) | BigInt.from(b);
  }
  return v;
}

RSAPrivateKey _loadPrivateKey() {
  final json =
      jsonDecode(File('tool/rsa_private.json').readAsStringSync()) as Map;
  return RSAPrivateKey(
    _fromB64(json['n'] as String),
    _fromB64(json['d'] as String),
    _fromB64(json['p'] as String),
    _fromB64(json['q'] as String),
  );
}

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage:');
    stderr.writeln('  token <fileNumber> <tier> [expiresInDays]');
    stderr.writeln('  payload <path>');
    exitCode = 64;
    return;
  }

  final key = _loadPrivateKey();

  switch (args[0]) {
    case 'token':
      if (args.length < 3) {
        stderr.writeln('token needs <fileNumber> <tier> [expiresInDays]');
        exitCode = 64;
        return;
      }
      final days = args.length > 3 ? int.tryParse(args[3]) : null;
      final token = SignedToken.mint(
        fileNumber: args[1],
        tier: args[2],
        privateKey: key,
        expiresAt:
            days == null ? null : DateTime.now().add(Duration(days: days)),
      );
      // ignore: avoid_print
      print(token.encode());
    case 'payload':
      final bytes = await File(args[1]).readAsBytes();
      // ignore: avoid_print
      print(base64Encode(SignatureService.signPayload(bytes, key)));
    default:
      stderr.writeln('Unknown mode: ${args[0]}');
      exitCode = 64;
  }
}
