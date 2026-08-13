import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/reticulum/reticulum_client.dart';

void main() {
  group('ReticulumClient frame protocol', () {
    test('encodeSend builds the expected JSON', () {
      final json = jsonDecode(ReticulumClient.encodeSend('abc123', '😀😁'))
          as Map<String, dynamic>;
      expect(json['type'], 'send');
      expect(json['to'], 'abc123');
      expect(json['payload'], '😀😁');
    });

    test('parses an identity frame', () {
      final frame = ReticulumClient.parseFrame(
          '{"type":"identity","address":"deadbeef"}');
      expect(frame, isA<IdentityFrame>());
      expect((frame as IdentityFrame).address, 'deadbeef');
    });

    test('parses a message frame', () {
      final frame = ReticulumClient.parseFrame(
          '{"type":"message","from":"peer1","payload":"😀😁"}');
      expect(frame, isA<MessageFrame>());
      final m = (frame as MessageFrame).message;
      expect(m.from, 'peer1');
      expect(m.payload, '😀😁');
    });

    test('parses an error frame', () {
      final frame =
          ReticulumClient.parseFrame('{"type":"error","detail":"no path"}');
      expect(frame, isA<ErrorFrame>());
      expect((frame as ErrorFrame).detail, 'no path');
    });

    test('returns null for garbage or unknown frames', () {
      expect(ReticulumClient.parseFrame('not json'), isNull);
      expect(ReticulumClient.parseFrame('{"type":"wat"}'), isNull);
    });
  });
}
