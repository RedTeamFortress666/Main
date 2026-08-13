import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_config.dart';
import 'polybius_operators.dart';

class AuthSession {
  AuthSession({
    required this.username,
    required this.displayName,
    required this.tier,
    this.isLocal = false,
  });
  final String username;
  final String displayName;
  final String tier;
  final bool isLocal;

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'tier': tier,
        'isLocal': isLocal,
      };

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        tier: j['tier'] as String,
        isLocal: j['isLocal'] as bool? ?? false,
      );
}

class _LocalAccount {
  _LocalAccount({
    required this.username,
    required this.displayName,
    required this.password,
    required this.pin,
    required this.tier,
  });

  final String username;
  final String displayName;
  final String password;
  final String pin;
  final String tier;

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'password': password,
        'pin': pin,
        'tier': tier,
      };

  factory _LocalAccount.fromJson(Map<String, dynamic> j) => _LocalAccount(
        username: j['username'] as String,
        displayName: j['displayName'] as String,
        password: j['password'] as String,
        pin: j['pin'] as String,
        tier: j['tier'] as String,
      );
}

class AuthService {
  static const _sessionKey = 'dd_session_v1';
  static const _localAccountsKey = 'dd_local_accounts_v1';

  Future<AuthSession?> currentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) return null;
    return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<_LocalAccount>> _loadLocalAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localAccountsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => _LocalAccount.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveLocalAccounts(List<_LocalAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localAccountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
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
    if (op != null) {
      return _persistSession(
        AuthSession(
          username: op.username,
          displayName: op.displayName,
          tier: op.tier,
        ),
      );
    }

    if (!AppConfig.isAllTier) return null;

    final locals = await _loadLocalAccounts();
    final u = username.trim().toUpperCase();
    for (final account in locals) {
      if (account.username.toUpperCase() != u) continue;
      final passOk =
          password == account.password || password == account.pin;
      if (passOk && pin == account.pin) {
        return _persistSession(
          AuthSession(
            username: account.username,
            displayName: account.displayName,
            tier: account.tier,
            isLocal: true,
          ),
        );
      }
    }
    return null;
  }

  Future<AuthSession?> registerLocalAccount({
    required String username,
    required String displayName,
    required String password,
    required String pin,
    required String tier,
  }) async {
    if (!AppConfig.isAllTier) return null;
    final u = username.trim();
    if (u.isEmpty || password.isEmpty || pin.length != 6) return null;

    final locals = await _loadLocalAccounts();
    if (locals.any((a) => a.username.toUpperCase() == u.toUpperCase())) {
      return null;
    }
    if (authenticatePolybiusAdmin(username: u, password: password, pin: pin) !=
        null) {
      return null;
    }

    locals.add(
      _LocalAccount(
        username: u.toUpperCase(),
        displayName: displayName.trim().isEmpty ? u : displayName.trim(),
        password: password,
        pin: pin,
        tier: tier,
      ),
    );
    await _saveLocalAccounts(locals);
    return _persistSession(
      AuthSession(
        username: u.toUpperCase(),
        displayName: displayName.trim().isEmpty ? u : displayName.trim(),
        tier: tier,
        isLocal: true,
      ),
    );
  }

  Future<AuthSession> _persistSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
