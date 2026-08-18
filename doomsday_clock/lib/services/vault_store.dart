import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/operator_card.dart';
import '../models/vault_card.dart';

class VaultStore {
  static const _key = 'journal_scanned_cards_v1';

  Future<List<VaultCard>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VaultCard.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(List<VaultCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<VaultCard>> upsert(OperatorCard incoming) async {
    final cards = await load();
    final idx = cards.indexWhere(
      (c) => c.card.username.toUpperCase() == incoming.username.toUpperCase(),
    );
    final next = VaultCard.fromCard(incoming);
    if (idx >= 0) {
      cards[idx] = VaultCard(
        id: cards[idx].id,
        card: incoming,
        receivedAt: DateTime.now(),
      );
    } else {
      cards.add(next);
    }
    await save(cards);
    return cards;
  }

  Future<List<VaultCard>> remove(String id) async {
    final cards = await load();
    cards.removeWhere((c) => c.id == id);
    await save(cards);
    return cards;
  }
}
