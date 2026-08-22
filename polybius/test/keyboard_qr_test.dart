import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/clock/animated_qr_codec.dart';
import 'package:polybius/features/clock/keyboard_qr_cipher.dart';
import 'package:polybius/features/clock/session_binary_key.dart';
import 'package:polybius/features/clock/widgets/make_qr_panel.dart';

void main() {
  group('SessionBinaryKey', () {
    test('create yields a 32-byte PBK key', () {
      final key = SessionBinaryKey.create();
      expect(key, startsWith(SessionBinaryKey.prefix));
      expect(SessionBinaryKey.isValid(key), isTrue);
      expect(SessionBinaryKey.decode(key), hasLength(32));
    });

    test('rejects generic strings and wrong lengths', () {
      expect(SessionBinaryKey.isValid('not-a-key'), isFalse);
      expect(SessionBinaryKey.isValid('PBK-abc'), isFalse);
      expect(
        () => SessionBinaryKey.decode('hunter2'),
        throwsFormatException,
      );
    });
  });

  group('KeyboardQrCipher', () {
    test('round-trips a dump for the same session key', () {
      final key = SessionBinaryKey.create();
      final dump = ScreenDump(
        text: 'typebox note',
        takenAt: DateTime.utc(2026, 8, 22, 17, 11),
        imageSha: 'abc',
      );
      final envelope = KeyboardQrCipher.seal(key, utf8.encode(dump.encode()));
      final opened = KeyboardQrCipher.open(key, envelope);
      expect(opened, isNotNull);
      final parsed = ScreenDump.tryParse(opened!);
      expect(parsed?.text, 'typebox note');
      expect(parsed?.imageSha, 'abc');
    });

    test('wrong key or tampered mac returns null', () {
      final a = SessionBinaryKey.create();
      final b = SessionBinaryKey.create();
      final envelope = KeyboardQrCipher.seal(a, utf8.encode('secret'));
      expect(KeyboardQrCipher.open(b, envelope), isNull);

      final map = jsonDecode(envelope) as Map<String, dynamic>;
      map['mac'] = base64Encode(List<int>.filled(32, 9));
      expect(KeyboardQrCipher.open(a, jsonEncode(map)), isNull);
    });
  });

  group('AnimatedQrCodec', () {
    test('splits and joins including a pipe inside a chunk', () {
      final key = SessionBinaryKey.create();
      final envelope = 'head${'x' * 200}|tail';
      final frames = AnimatedQrCodec.split(key, envelope);
      expect(frames.length, greaterThan(1));
      expect(frames.first, startsWith('PBK1|0|'));
      expect(AnimatedQrCodec.join(frames), envelope);
      expect(AnimatedQrCodec.join(frames.take(1)), isNull);
    });

    test('assembler ignores other sessions and generic QR', () {
      final key = SessionBinaryKey.create();
      final other = SessionBinaryKey.create();
      final sid = AnimatedQrCodec.sessionIdForKey(key);
      final frames = AnimatedQrCodec.split(key, 'payload');
      final foreign = AnimatedQrCodec.split(other, 'nope');
      final assembler = KeyboardQrAssembler(expectedSid: sid);

      expect(assembler.add('https://example.com'), isNull);
      expect(assembler.add(foreign.first), isNull);
      expect(assembler.add(frames.first), 'payload');
    });
  });

  group('MakeQrPanel', () {
    testWidgets('CREATE then CUT copies a PBK key', (tester) async {
      String? clipped;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipped = (call.arguments as Map)['text'] as String?;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': clipped};
          }
          return null;
        },
      );

      final enter = TextEditingController();
      final created = TextEditingController();
      String? last;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MakeQrPanel(
              enterController: enter,
              createdController: created,
              onEnter: (_) {},
              onCreated: (k) => last = k,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('session-key-create')));
      await tester.pump();
      expect(last, isNotNull);
      expect(SessionBinaryKey.isValid(last!), isTrue);
      expect(created.text, last);

      await tester.tap(find.byKey(const Key('session-key-cut')));
      await tester.pump();
      expect(clipped, last);
      expect(created.text, isEmpty);
    });
  });
}
