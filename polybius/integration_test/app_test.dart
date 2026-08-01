import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:polybius/app.dart';
import 'package:polybius/core/audio/music_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'package:polybius/features/cipher/screens/decrypt_tab.dart';
import 'package:polybius/features/cipher/screens/encrypt_tab.dart';

/// In-memory secret store so the test never touches platform secure storage.
class _MemorySecretStore implements PolybiusSecretStore {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

/// No-op music so the audio plugin (absent in headless tests) is never touched.
class _SilentMusicService extends MusicService {
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  Future<void> dispose() async {}
}

/// Pumps fixed frames instead of pumpAndSettle: the arcade menu and splash run
/// continuous animations, so pumpAndSettle would never settle.
Future<void> settle(WidgetTester tester,
    {int frames = 12, int ms = 100}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(Duration(milliseconds: ms));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('polybius_e2e');
    container = ProviderContainer(overrides: [
      secretStoreProvider.overrideWithValue(_MemorySecretStore()),
      musicServiceProvider.overrideWithValue(_SilentMusicService()),
    ]);
    await container.read(encryptionServiceProvider).init();
    await container.read(storageServiceProvider).init(hivePath: tempDir.path);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  testWidgets('login as DEVELOPER, open cipher, encrypt/decrypt round-trips',
      (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PolybiusApp(),
      ),
    );
    await settle(tester);

    // Splash/session-restore resolves to the login screen.
    expect(find.text('LOGIN'), findsOneWidget);

    final loginFields = find.byType(TextField);
    await tester.enterText(loginFields.at(0), 'DEVELOPER');
    await tester.enterText(loginFields.at(1), 'developer');
    await tester.tap(find.text('LOGIN'));
    await settle(tester);

    // Developer login lands on the arcade menu with cipher access granted.
    final cipherButton = find.text('◈ CIPHER ◈');
    expect(cipherButton, findsOneWidget);
    await tester.ensureVisible(cipherButton);
    await tester.pump();
    await tester.tap(cipherButton);
    await settle(tester);

    // ENCRYPT tab: turn plaintext into emoji ciphertext.
    const plaintext = 'MEET AT MIDNIGHT';
    await tester.enterText(
      find.descendant(of: find.byType(EncryptTab), matching: find.byType(TextField)),
      plaintext,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'ENCRYPT'));
    await settle(tester, frames: 4);

    final encOutput = tester.widget<SelectableText>(
      find.descendant(
        of: find.byType(EncryptTab),
        matching: find.byType(SelectableText),
      ),
    );
    final cipherText = encOutput.data ?? '';
    expect(cipherText.isNotEmpty, isTrue);
    expect(cipherText, isNot('...'));

    // Switch to DECRYPT tab and confirm the ciphertext round-trips.
    await tester.tap(find.text('🔓 DECRYPT'));
    await settle(tester, frames: 6);

    await tester.enterText(
      find.descendant(of: find.byType(DecryptTab), matching: find.byType(TextField)),
      cipherText,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'DECRYPT'));
    await settle(tester, frames: 4);

    final decOutput = tester.widget<SelectableText>(
      find.descendant(
        of: find.byType(DecryptTab),
        matching: find.byType(SelectableText),
      ),
    );
    expect(decOutput.data, plaintext);
  });
}
