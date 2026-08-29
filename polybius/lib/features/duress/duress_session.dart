import 'dart:convert';

import 'package:polybius/core/crypto/hkdf.dart';
import 'package:polybius/features/duress/cabinet_identity.dart';

/// In-memory only. Never written to Hive, never named in audit logs.
class DuressSession {
  const DuressSession({
    this.active = false,
    this.coverInitials = 'YOU',
    this.coverPlaintext = '',
    this.effectiveSeed,
  });

  final bool active;
  final String coverInitials;
  final String coverPlaintext;
  final String? effectiveSeed;

  /// HMAC-derived pool seed. Requires the cover PIN at arm time; the stored
  /// hash alone cannot reconstruct it.
  static String deriveSeed({
    required String realSeed,
    required String salt,
    required String pin,
  }) {
    final bytes = hmacSha256(
      utf8.encode(realSeed),
      utf8.encode('MIDNIGHT_CLIMAX::$salt::$pin'),
    );
    return base64Url.encode(bytes);
  }

  static DuressSession arm({
    required CabinetIdentity cabinet,
    required String realSeed,
    required String pin,
  }) {
    return DuressSession(
      active: true,
      coverInitials: cabinet.coverInitials,
      coverPlaintext: cabinet.coverPlaintext,
      effectiveSeed: deriveSeed(
        realSeed: realSeed,
        salt: cabinet.coverSalt,
        pin: pin,
      ),
    );
  }

  static const idle = DuressSession();
}
