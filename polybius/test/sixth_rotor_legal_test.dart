import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/cipher/screens/sixth_rotor_plate.dart';

void main() {
  const smallprint = "wutang clan ain't nuthin' 2 fuq with";
  const heading = '6th rotor LLÇ 2026*';

  test('physical paper and EULA carry the Oracle protocol and the smallprint',
      () {
    final paper = File('LEGAL/PHYSICAL_PAPER.md').readAsStringSync();
    final eula = File('LEGAL/EULA.md').readAsStringSync();
    final cd = File('LEGAL/CEASE_AND_DESIST_TEMPLATE.md').readAsStringSync();
    final index = File('LEGAL/README.md').readAsStringSync();

    for (final body in [paper, eula, cd]) {
      expect(body, contains('antique Enigma'));
      expect(body, contains('Colossus'));
      expect(body, contains('twenty-four'));
      expect(body, contains('Oracle'));
    }
    expect(paper, contains(heading));
    expect(paper, contains(smallprint));
    expect(paper, contains('PA+'));
    expect(eula, contains(heading));
    expect(eula, contains(smallprint));
    expect(eula, contains('## 11. Prompt integrity'));
    expect(eula, contains('## 12. Sixth rotor'));
    expect(index, contains('PHYSICAL_PAPER.md'));
    expect(
      paper.toLowerCase(),
      contains('not an affiliation'),
      reason: 'Wu-Tang line is epigraph, not a joint venture',
    );
  });

  testWidgets('sixth rotor plate prints the heading and smallprint',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SixthRotorPlate())),
    );
    expect(find.byKey(const ValueKey<String>('sixth-rotor-llç-2026')),
        findsOneWidget);
    expect(find.text(heading), findsOneWidget);
    expect(find.text(smallprint), findsOneWidget);
    expect(find.textContaining('NOT IN THE ODOMETER'), findsOneWidget);
  });
}
