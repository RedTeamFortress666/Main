import 'dart:convert';
import 'dart:math';

import 'package:polybius/features/cipher/engine/pool_sync.dart';

/// Typed Bluetooth envelopes so peers can exchange ciphertext and
/// mutually-confirmed rotor / pool shares.
enum BtEnvelopeKind {
  cipher,
  rotorOffer,
  rotorAck,
  rotorReject,
  unknown,
}

class BtEnvelope {
  const BtEnvelope({
    required this.kind,
    this.payload = '',
    this.confirmCode,
    this.poolId,
  });

  final BtEnvelopeKind kind;
  final String payload;
  final String? confirmCode;
  final String? poolId;

  static const _prefix = 'PB1|';

  String encode() {
    final map = <String, dynamic>{
      'k': switch (kind) {
        BtEnvelopeKind.cipher => 'c',
        BtEnvelopeKind.rotorOffer => 'ro',
        BtEnvelopeKind.rotorAck => 'ra',
        BtEnvelopeKind.rotorReject => 'rr',
        BtEnvelopeKind.unknown => '?',
      },
      if (payload.isNotEmpty) 'p': payload,
      if (confirmCode != null) 'code': confirmCode,
      if (poolId != null) 'pid': poolId,
    };
    return '$_prefix${base64Url.encode(utf8.encode(jsonEncode(map)))}';
  }

  static BtEnvelope parse(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith(_prefix)) {
      // Legacy plain emoji ciphertext.
      return BtEnvelope(kind: BtEnvelopeKind.cipher, payload: trimmed);
    }
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(trimmed.substring(_prefix.length))),
      ) as Map<String, dynamic>;
      final k = decoded['k'] as String? ?? '?';
      final kind = switch (k) {
        'c' => BtEnvelopeKind.cipher,
        'ro' => BtEnvelopeKind.rotorOffer,
        'ra' => BtEnvelopeKind.rotorAck,
        'rr' => BtEnvelopeKind.rotorReject,
        _ => BtEnvelopeKind.unknown,
      };
      return BtEnvelope(
        kind: kind,
        payload: (decoded['p'] as String?) ?? '',
        confirmCode: decoded['code'] as String?,
        poolId: decoded['pid'] as String?,
      );
    } catch (_) {
      return BtEnvelope(kind: BtEnvelopeKind.cipher, payload: trimmed);
    }
  }

  static String generateConfirmCode([Random? random]) {
    final rng = random ?? Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  static BtEnvelope cipher(String emojiCiphertext) => BtEnvelope(
        kind: BtEnvelopeKind.cipher,
        payload: emojiCiphertext,
      );

  static BtEnvelope rotorOffer({
    required PoolSync token,
    required String confirmCode,
  }) =>
      BtEnvelope(
        kind: BtEnvelopeKind.rotorOffer,
        payload: token.encode(),
        confirmCode: confirmCode,
        poolId: token.poolId,
      );

  static BtEnvelope rotorAck(String confirmCode) => BtEnvelope(
        kind: BtEnvelopeKind.rotorAck,
        confirmCode: confirmCode,
      );

  static BtEnvelope rotorReject(String confirmCode) => BtEnvelope(
        kind: BtEnvelopeKind.rotorReject,
        confirmCode: confirmCode,
      );
}
