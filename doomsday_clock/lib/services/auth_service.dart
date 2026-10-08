import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'polybius_operators.dart';

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

  /// Marks the vault as armed. Does **not** seed player/APK cards —
  /// PØLYBĪUS is launched from Planner OPEN, not listed as a download.
  Future<void> seedUserVault(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_entries_${username.toUpperCase()}';
    if (prefs.containsKey(key)) return;
    await prefs.setString(key, jsonEncode(<Map<String, dynamic>>[]));
    await prefs.setString(
      'vault_payload_${username.toUpperCase()}',
      'polybius',
    );
  }
}
