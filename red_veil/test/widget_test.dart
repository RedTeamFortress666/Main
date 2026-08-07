import 'package:flutter_test/flutter_test.dart';
import 'package:red_veil/main.dart';

void main() {
  testWidgets('RED VEIL control screen renders', (tester) async {
    await tester.pumpWidget(const RedVeilApp());
    expect(find.text('RED VEIL'), findsOneWidget);
    expect(find.text('ENABLE FILTER'), findsOneWidget);
  });
}
