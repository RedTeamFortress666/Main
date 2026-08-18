import 'package:flutter_test/flutter_test.dart';

import 'package:doomsday_clock/data/polybius_operator_cards.dart';
import 'package:doomsday_clock/models/operator_card.dart';
import 'package:doomsday_clock/services/qr_card_codec.dart';

void main() {
  test('POLYBIUS_CARD_V1 hydrates roster secrets', () {
    final encoded = QrCardCodec.encodePolybiusCard(
      username: 'GAM3.0N',
      displayName: 'Gam3.0n',
      tier: 'developer',
      inviteCode: 'B1-66-3R',
    );
    expect(encoded.startsWith(QrCardCodec.polybiusPrefix), isTrue);

    final decoded = QrCardCodec.decode(encoded);
    expect(decoded, isNotNull);
    expect(decoded!.username, 'GAM3.0N');
    expect(decoded.password, 'Dig1tal.Ra1n99');
    expect(decoded.pin, '816639');
    expect(decoded.backupPassword, '01-p0lyb1u5-10');
  });

  test('DOOMSDAY_CHERRY_V1 round-trips explicit secrets', () {
    const card = OperatorCard(
      username: 'TESTOP',
      displayName: 'Test Op',
      inviteCode: 'T3-ST-0P',
      pin: '123456',
      password: 'secret',
      backupPassword: 'backup',
      tier: 'agent',
    );
    final encoded = QrCardCodec.encodeCherryCard(card);
    final decoded = QrCardCodec.decode(encoded);
    expect(decoded, isNotNull);
    expect(decoded!.username, 'TESTOP');
    expect(decoded.password, 'secret');
    expect(decoded.pin, '123456');
  });

  test('unknown polybius card keeps public identity without invented secrets', () {
    final encoded = QrCardCodec.encodePolybiusCard(
      username: 'NOBODY',
      displayName: 'Nobody',
      tier: 'guest',
      inviteCode: 'XX-00-00',
    );
    final decoded = QrCardCodec.decode(encoded)!;
    expect(decoded.username, 'NOBODY');
    expect(decoded.password, isEmpty);
    expect(decoded.pin, isEmpty);
  });

  test('roster lookup is case-insensitive', () {
    expect(PolybiusOperatorCards.findByUsername('spamkat2')?.username, 'SPAMKAT2');
  });
}
