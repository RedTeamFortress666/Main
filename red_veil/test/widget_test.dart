import 'package:flutter_test/flutter_test.dart';
import 'package:red_veil/main.dart';

void main() {
  testWidgets('DARTH CHERRY control screen renders', (tester) async {
    await tester.pumpWidget(const DarthCherryApp());
    expect(find.text('DARTH CHERRY'), findsOneWidget);
    expect(find.text('ENABLE FILTER'), findsOneWidget);
    expect(find.textContaining('Polybius'), findsNothing);
    expect(find.textContaining('eyeball'), findsNothing);
    expect(find.textContaining('plaintext'), findsNothing);
  });
}
