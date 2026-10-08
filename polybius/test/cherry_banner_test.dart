import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/redlight/cabinet_policy.dart';
import 'package:polybius/features/redlight/cherry_banner.dart';
import 'package:polybius/features/redlight/leak_detector.dart';

void main() {
  testWidgets('Darth Cherry banner shows lockup and leak sweep', (tester) async {
    final report = LeakDetector.scan(
      const LeakSnapshot(
        policy: CabinetPolicy.woven,
        mixer: 'mixer-secret',
        operatorUsername: 'DEVELOPER',
        sessionIsV2: true,
        derangeSecret: 'mixer-secret',
        redlightSealed: true,
        hybridPqLive: true,
        stegoVetBound: true,
        roundTableArmed: true,
        glassesPaired: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CherryBanner(lampOn: true, report: report),
        ),
      ),
    );
    expect(find.textContaining('CHERRY'), findsOneWidget);
    expect(find.textContaining('PHOSPHOR MAP LIVE'), findsOneWidget);
    expect(find.textContaining('LEAK SWEEP'), findsOneWidget);
  });
}
