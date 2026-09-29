import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shadownet/main.dart';

void main() {
  testWidgets('Shadøwnet shell loads', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShadownetApp()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('SHADØWNET'), findsOneWidget);
  });
}
