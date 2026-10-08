import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';

void main() {
  List<int> mac(List<int> data) =>
      Hmac(sha256, utf8.encode('test-device-key')).convert(data).bytes;

  test('issued ticket verifies and rejects a swapped operator', () {
    final ticket = V2SessionTicket.issue(username: 'developer', mac: mac);
    expect(ticket.username, 'DEVELOPER');
    expect(ticket.verify(mac), isTrue);
    expect(V2SessionTicket.parse(ticket.wire)?.verify(mac), isTrue);

    final swapped = 'v2:INTRUDER:${ticket.issuedMs}:${ticket.nonceB64}:${ticket.macB64}';
    final parsed = V2SessionTicket.parse(swapped);
    expect(parsed, isNotNull);
    expect(parsed!.verify(mac), isFalse);
  });

  test('tampered MAC fails', () {
    final ticket = V2SessionTicket.issue(username: 'AGENT', mac: mac);
    final wire = ticket.wire.replaceFirst(ticket.macB64, 'AAAA');
    final parsed = V2SessionTicket.parse(wire);
    expect(parsed, isNotNull);
    expect(parsed!.verify(mac), isFalse);
  });

  test('legacy username is not a ticket', () {
    expect(V2SessionTicket.parse('DEVELOPER'), isNull);
    expect(V2SessionTicket.parse('v2:only:three'), isNull);
  });

  test('a ticket ages out at ticketMaxAge even with a valid MAC', () {
    final issued = DateTime.utc(2026, 9, 1);
    final ticket = V2SessionTicket.issue(
      username: 'AGENT',
      mac: mac,
      issuedMs: issued.millisecondsSinceEpoch,
    );
    expect(ticket.verify(mac), isTrue);
    expect(ticket.isExpired(now: issued.add(const Duration(days: 13))), isFalse);
    expect(ticket.isExpired(now: issued.add(const Duration(days: 15))), isTrue);
    expect(
      ticket.isExpired(now: issued.subtract(const Duration(minutes: 1))),
      isTrue,
      reason: 'a rolled-back clock does not stretch a ticket',
    );
    expect(V2LoginProtocol.ticketMaxAge, const Duration(days: 14));
  });
}
