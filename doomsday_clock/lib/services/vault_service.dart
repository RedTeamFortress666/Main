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
  static const _vaultKey = 'vault_entries_v1';
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

  Future<bool> isVaultOpenToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_unlockedDayKey) == dayKey();
  }

  Future<void> unlockVaultForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unlockedDayKey, dayKey());
    // Seed default vault contents once.
    final existing = await loadVault();
    if (existing.isEmpty) {
      await saveVault([
        VaultEntry(
          id: 'polybius',
          title: 'PØLYBĪUS Admin APK',
          detail: 'Emoji cipher / operator portal',
          apkHint:
              'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/polybius-1.0.0-beta.2-android-arm64.apk',
        ),
        VaultEntry(
          id: 'darth',
          title: 'DARTH CHERRY',
          detail: 'Night red-light screen dimmer',
          apkHint:
              'https://github.com/RedTeamFortress666/Main/raw/cursor/polybius-flutter-app-a932/polybius/dist/darth-cherry-1.0.2-android-arm64.apk',
        ),
        VaultEntry(
          id: 'press',
          title: 'POLYBIUS PRESS notes',
          detail: 'SD / firmware organiser stage plans',
          apkHint: null,
        ),
      ]);
    }
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
