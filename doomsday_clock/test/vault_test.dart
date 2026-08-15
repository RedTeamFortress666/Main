import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doomsday_clock/services/auth_service.dart';
import 'package:doomsday_clock/services/bulletin_service.dart';
import 'package:doomsday_clock/services/polybius_launcher.dart';
import 'package:doomsday_clock/services/polybius_operators.dart';
import 'package:doomsday_clock/services/vault_service.dart';

void main() {
  test('ritual words rotate by day and match contiguous input', () {
    final v = VaultService();
    final day = DateTime(2026, 8, 9);
    final phrase = v.ritualPhraseFor(day);
    expect(phrase.split(' '), hasLength(3));
    expect(v.matchesRitual(phrase, day), isTrue);
    expect(v.matchesRitual('prefix $phrase suffix', day), isTrue);
    expect(v.matchesRitual('wrong words here', day), isFalse);
  });

  test('polybius admin auth accepts Art3mas and rejects bad pin', () {
    final ok = authenticatePolybiusAdmin(
      username: 'Art3mas',
      password: 'BowArrow7',
      pin: '271828',
    );
    expect(ok, isNotNull);
    expect(ok!.tier, 'admin');

    final bad = authenticatePolybiusAdmin(
      username: 'Art3mas',
      password: 'BowArrow7',
      pin: '000000',
    );
    expect(bad, isNull);
  });

  test('bulletin source is BAS', () {
    expect(BulletinService.sourceUrl, contains('thebulletin.org'));
  });

  test('concealed payload packages are user and HQ, not a card URL', () {
    expect(PolybiusLauncher.userPackage, 'com.polybius.polybius.user');
    expect(PolybiusLauncher.hqPackage, 'com.polybius.polybius.hq');
    expect(PolybiusLauncher.activity, 'com.polybius.polybius.MainActivity');
  });

  test('vault seed stores no player cards or APK links', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService();
    await auth.seedUserVault('ART3MAS');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('vault_entries_ART3MAS'), '[]');
    expect(prefs.getString('vault_payload_ART3MAS'), 'polybius');
    expect(prefs.getString('vault_entries_ART3MAS'), isNot(contains('apk')));
    expect(prefs.getString('vault_entries_ART3MAS'), isNot(contains('http')));
  });

  test('vault service has no download-card entry API', () {
    expect(VaultService().newId(), startsWith('n_'));
  });
}
