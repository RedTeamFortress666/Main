import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/cards/user_card_codec.dart';

void main() {
  test('operator card QR round-trips public identity without secrets', () {
    const card = PolybiusUserCard(
      username: 'GAM3.0N',
      displayName: 'Gam3.0n',
      tier: 'developer',
      inviteCode: 'B1-66-3R',
    );
    final encoded = card.encode();
    expect(encoded.startsWith(PolybiusUserCard.prefix), isTrue);
    expect(encoded.toLowerCase().contains('password'), isFalse);

    final decoded = PolybiusUserCard.tryParse(encoded);
    expect(decoded, isNotNull);
    expect(decoded!.username, 'GAM3.0N');
    expect(decoded.tier, 'developer');
    expect(decoded.inviteCode, 'B1-66-3R');
  });

  test('rejects unrelated payloads', () {
    expect(PolybiusUserCard.tryParse('not-a-card'), isNull);
    expect(PolybiusUserCard.tryParse('DOOMSDAY_CHERRY_V1:abc'), isNull);
  });
}
