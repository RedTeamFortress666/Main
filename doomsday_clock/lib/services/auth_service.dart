import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'polybius_operators.dart';
import '../models/models.dart';
import 'vault_service.dart';

class AuthSession {
  AuthSession({required this.username, required this.displayName, required this.tier});
  final String username;
  final String displayName;
  final String tier;

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'tier': tier,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        tier: j['tier'] as String,
      );
}

class AuthService {
  static const _sessionKey = 'dd_session_v1';
  static const _vaultSetupKeyPrefix = 'dd_vault_setup_';

  /// Canonical raw links for vault APK slots (branch-pinned).
  static const portalApkUrl =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/polybius/dist/polybius-v1-stable-hq-android-arm64.apk';
  static const darthCherryApkUrl =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/polybius/dist/darth-cherry-1.0.2-android-arm64.apk';
  static const devPortalApkUrl =
      'https://github.com/RedTeamFortress666/Main/raw/cursor/pool-pin-bt-ui-d8fa/polybius/dist/polybius-portal-dev-mechah-android-arm64.apk';

  /// Inject MechaH Dev Portal slot after 20 April ritual (idempotent).
  Future<List<VaultEntry>> ensureMechaHDevPortal(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_entries_${username.toUpperCase()}';
    final raw = prefs.getString(key);
    final list = raw == null
        ? <VaultEntry>[]
        : (jsonDecode(raw) as List<dynamic>)
            .map((e) => VaultEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
    if (list.any((e) => e.id == 'portal-dev-mechah')) {
      return list;
    }
    list.add(
      VaultEntry(
        id: 'portal-dev-mechah',
        title: 'PØLYBÎŪS PORTAL · DEV · MECHAH',
        detail:
            'Happy Birthday MechaH! I grok thee — embedded Dev Portal ready to install.',
        apkHint: devPortalApkUrl,
        assetApk: VaultService.assetDevPortalApk,
        concealable: true,
        concealed: false,
      ),
    );
    await prefs.setString(
      key,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    return list;
  }

  Future<AuthSession?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<AuthSession?> login({
    required String username,
    required String password,
    required String pin,
  }) async {
    final op = authenticatePolybiusAdmin(
      username: username,
      password: password,
      pin: pin,
    );
    if (op == null) return null;
    final session = AuthSession(
      username: op.username,
      displayName: op.displayName,
      tier: op.tier,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<bool> needsVaultSetup(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_vaultSetupKeyPrefix${username.toUpperCase()}') ??
        false);
  }

  Future<void> markVaultSetupComplete(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      '$_vaultSetupKeyPrefix${username.toUpperCase()}',
      true,
    );
  }

  Future<void> seedUserVault(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_entries_${username.toUpperCase()}';
    if (prefs.containsKey(key)) {
      // Migrate older seeds: ensure portal slot is concealable.
      await _ensureConcealablePortal(prefs, key);
      return;
    }
    final seed = [
      VaultEntry(
        id: 'portal',
        title: 'PØLYBÎŪS PORTAL',
        detail: 'Operator access portal + cipher (concealable)',
        apkHint: portalApkUrl,
        concealable: true,
        concealed: false,
      ),
      VaultEntry(
        id: 'darth',
        title: 'DARTH CHERRY',
        detail: 'Required for GRØK-REBEL alarm veil',
        apkHint: darthCherryApkUrl,
      ),
      VaultEntry(
        id: 'grok',
        title: 'GRØK-REBEL 6.0',
        detail: 'Local uncensored AI loader (alarm veil)',
        apkHint: null,
      ),
    ];
    await prefs.setString(
      key,
      jsonEncode(seed.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _ensureConcealablePortal(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => VaultEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    var changed = false;
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      final isPortal = e.id == 'portal' ||
          e.id == 'polybius' ||
          e.title.toUpperCase().contains('PORTAL') ||
          e.title.toUpperCase().contains('PØLYB');
      if (isPortal && (!e.concealable || e.id == 'polybius')) {
        list[i] = e.copyWith(
          title: 'PØLYBÎŪS PORTAL',
          detail: 'Operator access portal + cipher (concealable)',
          concealable: true,
        );
        // Keep id stable for prefs; rename polybius → portal when rewriting.
        if (e.id == 'polybius') {
          list[i] = VaultEntry(
            id: 'portal',
            title: 'PØLYBÎŪS PORTAL',
            detail: 'Operator access portal + cipher (concealable)',
            apkHint: e.apkHint ?? portalApkUrl,
            concealable: true,
            concealed: e.concealed,
          );
        }
        changed = true;
      }
    }
    if (changed) {
      await prefs.setString(
        key,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    }
  }

  Future<void> saveUserVault(String username, List<VaultEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_entries_${username.toUpperCase()}';
    await prefs.setString(
      key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
