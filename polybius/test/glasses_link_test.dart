import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/glasses/cover_screensaver.dart';
import 'package:polybius/features/glasses/glasses_link.dart';
import 'package:polybius/features/redlight/redlight_vault.dart';

void main() {
  List<int> macA(List<int> data) =>
      List<int>.generate(32, (i) => (data.length + i + 3) & 0xff);
  List<int> macB(List<int> data) =>
      List<int>.generate(32, (i) => (data.length + i + 9) & 0xff);

  test('glasses session verifies on the minting key only', () {
    final session = GlassesSession.issue(owner: 'developer', deviceMac: macA);
    expect(session.owner, 'DEVELOPER');
    expect(session.verify(macA), isTrue);
    expect(session.verify(macB), isFalse);
    final parsed = GlassesSession.parse(session.wire);
    expect(parsed, isNotNull);
    expect(parsed!.verify(macA), isTrue);
  });

  test('HUD frame carries lamp jitter, not the mixer', () {
    final profile = RedlightProfile.mint(owner: 'DEVELOPER');
    final hud = HudFrame.fromProfile(profile, phosphor: true);
    final json = hud.toJson();
    expect(json['owner'], 'DEVELOPER');
    expect(json.containsKey('mixer'), isFalse);
    expect(json.containsKey('secret'), isFalse);
    expect(json['phosphor'], isTrue);
  });

  testWidgets('cover screensaver shows attract copy', (tester) async {
    var woke = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CoverScreensaver(
          canWake: true,
          onOperatorWake: () => woke = true,
        ),
      ),
    );
    expect(find.byKey(const ValueKey<String>('cover-screensaver')), findsOneWidget);
    expect(find.text('INSERT  COIN'), findsOneWidget);
    expect(find.text('ATTRACT MODE'), findsOneWidget);
    await tester.tap(find.byType(CoverScreensaver));
    expect(woke, isTrue);
  });
}
