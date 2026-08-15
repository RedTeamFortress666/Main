import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'polybius_operators.dart';
import '../models/models.dart';

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
    if (prefs.containsKey(key)) return;
    final seed = [
      VaultEntry(
        id: 'polybius',
        title: 'PØLYBĪUS Admin APK',
        detail: 'Operator portal + cipher',
        apkHint:
            'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/polybius-1.0.0-beta.2-android-arm64.apk',
      ),
      VaultEntry(
        id: 'darth',
        title: 'DARTH CHERRY',
        detail: 'Required for GRØK-REBEL alarm veil',
        apkHint:
            'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/darth-cherry-1.0.2-android-arm64.apk',
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
}
