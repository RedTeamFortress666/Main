import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PØLYBĪUS V2 login protocol.
///
/// The arcade still takes OPERATOR ID + ACCESS KEY. V2 adds a device-bound
/// session ticket so the session box is not a bare username anyone can swap.
/// The MAC key is the working AES key (keystore-backed on native, obfuscation
/// on web — see BUILD.md). A ticket is not a password proof after the fact;
/// it only binds "this device already accepted this operator".
class V2LoginProtocol {
  V2LoginProtocol._();

  static const int version = 2;
  static const String name = 'PØLYBĪUS V2';
  static const String wirePrefix = 'v2';

  /// A ticket older than this is dropped on restore and the operator logs
  /// in again. The MAC still verifies — age is a separate check, so a
  /// copied session box does not stay valid forever.
  static const Duration ticketMaxAge = Duration(days: 14);
}

class V2HandshakeLine {
  const V2HandshakeLine({
    required this.code,
    required this.label,
    required this.status,
  });

  final String code;
  final String label;
  final String status;
}

class V2HandshakeLog {
  const V2HandshakeLog({
    this.lines = const [],
    this.finished = false,
    this.ok = false,
  });

  final List<V2HandshakeLine> lines;
  final bool finished;
  final bool ok;

  static const empty = V2HandshakeLog();
}

class V2SessionTicket {
  const V2SessionTicket({
    required this.username,
    required this.issuedMs,
    required this.nonceB64,
    required this.macB64,
  });

  final String username;
  final int issuedMs;
  final String nonceB64;
  final String macB64;

  String get wire =>
      '${V2LoginProtocol.wirePrefix}:$username:$issuedMs:$nonceB64:$macB64';

  static String nonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static List<int> _payload(String username, int issuedMs, String nonceB64) {
    return utf8.encode(
      'V2LOGIN::${username.toUpperCase()}::$issuedMs::$nonceB64',
    );
  }

  static bool _macEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static V2SessionTicket issue({
    required String username,
    required List<int> Function(List<int> data) mac,
    int? issuedMs,
    String? nonceB64,
  }) {
    final user = username.trim().toUpperCase();
    final issued = issuedMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    final nonceValue = nonceB64 ?? nonce();
    final digest = mac(_payload(user, issued, nonceValue));
    return V2SessionTicket(
      username: user,
      issuedMs: issued,
      nonceB64: nonceValue,
      macB64: base64Url.encode(digest),
    );
  }

  static V2SessionTicket? parse(String wire) {
    final parts = wire.split(':');
    if (parts.length != 5) return null;
    if (parts[0] != V2LoginProtocol.wirePrefix) return null;
    final user = parts[1].trim().toUpperCase();
    final issued = int.tryParse(parts[2]);
    if (user.isEmpty || issued == null) return null;
    if (parts[3].isEmpty || parts[4].isEmpty) return null;
    return V2SessionTicket(
      username: user,
      issuedMs: issued,
      nonceB64: parts[3],
      macB64: parts[4],
    );
  }

  bool verify(List<int> Function(List<int> data) mac) {
    List<int> expected;
    List<int> actual;
    try {
      expected = mac(_payload(username, issuedMs, nonceB64));
      actual = base64Url.decode(macB64);
    } catch (_) {
      return false;
    }
    return _macEqual(expected, actual);
  }

  DateTime get issuedAt =>
      DateTime.fromMillisecondsSinceEpoch(issuedMs, isUtc: true);

  Duration age({DateTime? now}) => (now ?? DateTime.now()).toUtc().difference(issuedAt);

  /// Tickets from the future count as expired — a clock rolled back to
  /// stretch a ticket is the same failure as one that ran out.
  bool isExpired({
    DateTime? now,
    Duration maxAge = V2LoginProtocol.ticketMaxAge,
  }) {
    final a = age(now: now);
    return a.isNegative || a > maxAge;
  }

  /// SHA-256 of the wire form — display only, not a security boundary.
  String get fingerprint =>
      sha256.convert(utf8.encode(wire)).toString().substring(0, 8).toUpperCase();
}
