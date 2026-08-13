import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cherry_vault_card.dart';

class CherryVaultStore {
  String _key(String username) =>
      'cherry_vault_cards_${username.trim().toUpperCase()}';

  Future<List<CherryVaultCard>> load(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(username));
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CherryVaultCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(String username, List<CherryVaultCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(username),
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }

  Future<CherryVaultCard?> upsert(String username, CherryVaultCard incoming) async {
    final cards = await load(username);
    final idx = cards.indexWhere(
      (c) => c.username.toUpperCase() == incoming.username.toUpperCase(),
    );
    if (idx >= 0) {
      cards[idx] = CherryVaultCard(
        id: cards[idx].id,
        username: incoming.username,
        displayName: incoming.displayName,
        inviteCode: incoming.inviteCode,
        pin: incoming.pin,
        password: incoming.password,
        backupPassword: incoming.backupPassword,
        tier: incoming.tier,
        receivedAt: DateTime.now(),
      );
    } else {
      cards.add(incoming);
    }
    await save(username, cards);
    return idx >= 0 ? cards[idx] : cards.last;
  }

  Future<void> remove(String username, String cardId) async {
    final cards = await load(username);
    cards.removeWhere((c) => c.id == cardId);
    await save(username, cards);
  }
}
