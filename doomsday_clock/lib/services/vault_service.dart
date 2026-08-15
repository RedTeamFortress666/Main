import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Daily planner notes + hidden vault.
///
/// Vault unlock: type today's ritual words into the note field, then
/// **hold SAVE NOTE for 3 seconds** until the control reads OPEN.
class VaultService {
  static const _notesKey = 'planner_notes_v1';
  static const _unlockedDayKey = 'vault_unlocked_day';

  /// Word lists rotate by calendar day — operator must enter the phrase for *today*.
  static const _wordBank = [
    ['ash', 'meridian', 'quiet'],
    ['violet', 'static', 'harbour'],
    ['iron', 'lullaby', 'zero'],
    ['ember', 'corridor', 'nine'],
    ['glass', 'oracle', 'drift'],
    ['copper', 'siren', 'fold'],
    ['nylon', 'eclipse', 'ward'],
  ];

  String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Today's required words (space-separated, order matters).
  List<String> ritualWordsFor(DateTime day) {
    final idx = day.difference(DateTime(day.year)).inDays % _wordBank.length;
    return List<String>.from(_wordBank[idx]);
  }

  String ritualPhraseFor(DateTime day) => ritualWordsFor(day).join(' ');

  bool matchesRitual(String input, DateTime day) {
    final want = ritualWordsFor(day).map((w) => w.toLowerCase()).toList();
    final got = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (got.length < want.length) return false;
    // Allow the ritual words to appear as a contiguous sequence in the note.
    for (var i = 0; i <= got.length - want.length; i++) {
      var ok = true;
      for (var j = 0; j < want.length; j++) {
        if (got[i + j] != want[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  Future<List<PlannerNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PlannerNote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveNotes(List<PlannerNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notesKey,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<bool> isVaultOpenForDay(String username, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_unlocked_${username.toUpperCase()}_${dayKey(day)}';
    return prefs.getBool(key) ?? false;
  }

  Future<void> unlockVaultForDay(String username, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'vault_unlocked_${username.toUpperCase()}_${dayKey(day)}';
    await prefs.setBool(key, true);
  }

  Future<bool> isVaultOpenToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unlockedDayKey) == dayKey();
  }

  Future<void> unlockVaultForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unlockedDayKey, dayKey());
  }

  String newId() =>
      'n_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
}
