import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Daily planner notes + hidden vault.
///
/// Vault unlock: select **5 November** on the calendar, enter the Gunpowder
/// Plot riddle into the note field, then **hold SAVE NOTE for 3 seconds**
/// until the control reads OPEN.
class VaultService {
  static const _notesKey = 'planner_notes_v1';
  static const _vaultKey = 'vault_entries_v1';
  static const _unlockedDayKey = 'vault_unlocked_day';

  /// Guy Fawkes / Gunpowder Plot riddle — vault opens only on 5 November
  /// when this phrase is held in SAVE NOTE.
  static const gunpowderRiddle =
      'Remember Remember the 5th of November, the gunpowder treason and plot- '
      'I know of no reason why gunpowder treason should ever be forgot';

  String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Unlock calendar day: 5 November (any year).
  bool isUnlockDay(DateTime day) => day.month == 11 && day.day == 5;

  /// Canonical ritual phrase (for tests / operator docs).
  String ritualPhraseFor(DateTime day) =>
      isUnlockDay(day) ? gunpowderRiddle : '';

  /// Normalize text for riddle comparison: letters/digits only, lowercased.
  static String normalizeRitual(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool matchesRitual(String input, DateTime day) {
    if (!isUnlockDay(day)) return false;
    final want = normalizeRitual(gunpowderRiddle);
    final got = normalizeRitual(input);
    if (got.isEmpty) return false;
    // Exact match or note contains the full riddle as a contiguous phrase.
    return got == want || got.contains(want);
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

  Future<List<VaultEntry>> loadVault() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vaultKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => VaultEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveVault(List<VaultEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _vaultKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addVaultEntry(VaultEntry entry) async {
    final list = await loadVault();
    list.add(entry);
    await saveVault(list);
  }

  String newId() =>
      'n_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
}
