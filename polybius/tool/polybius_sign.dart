// Offline signer for PØLYBĪUS. Requires the PRIVATE key from
// tool/polybius_keys.dart. Run on a trusted machine only.
//
// Mint a signed invite/license token:
//   dart run tool/polybius_sign.dart token <privateB64> <fileNumber> <tier> [expiresInDays]
//
// Sign an update payload file (prints a detached signature):
//   dart run tool/polybius_sign.dart payload <privateB64> <path>
import 'dart:convert';
import 'dart:io';

import 'package:polybius/core/crypto/signature_service.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('Usage:');
    stderr.writeln('  token <privateB64> <fileNumber> <tier> [expiresInDays]');
    stderr.writeln('  payload <privateB64> <path>');
    exitCode = 64;
    return;
  }

  final mode = args[0];
  final privateSeed = base64Decode(args[1]);

  switch (mode) {
    case 'token':
      if (args.length < 4) {
        stderr.writeln('token needs <fileNumber> <tier> [expiresInDays]');
        exitCode = 64;
        return;
      }
      final expiresInDays = args.length > 4 ? int.tryParse(args[4]) : null;
      final token = await SignedToken.mint(
        fileNumber: args[2],
        tier: args[3],
        privateSeed: privateSeed,
        expiresAt: expiresInDays == null
            ? null
            : DateTime.now().add(Duration(days: expiresInDays)),
      );
      // ignore: avoid_print
      print(token.encode());
    case 'payload':
      final bytes = await File(args[2]).readAsBytes();
      final sig = await SignatureService.signPayload(bytes, privateSeed);
      // ignore: avoid_print
      print(base64Encode(sig));
    default:
      stderr.writeln('Unknown mode: $mode');
      exitCode = 64;
  }
}
