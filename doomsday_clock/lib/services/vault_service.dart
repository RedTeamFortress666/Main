import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Daily planner notes + hidden vault.
///
/// Rituals (select calendar day → type phrase → hold SAVE NOTE 3s):
/// - **5 November** — Gunpowder Plot riddle → opens personal vault
/// - **20 April** — MechaH birthday line → vault + injects Dev Portal APK slot
class VaultService {
  static const _notesKey = 'planner_notes_v1';
  static const _vaultKey = 'vault_entries_v1';
  static const _unlockedDayKey = 'vault_unlocked_day';

  /// Guy Fawkes / Gunpowder Plot riddle — vault opens only on 5 November
  /// when this phrase is held in SAVE NOTE.
  static const gunpowderRiddle =
      'Remember Remember the 5th of November, the gunpowder treason and plot- '
      'I know of no reason why gunpowder treason should ever be forgot';

  /// MechaH birthday unlock — 20 April.
  static const mechaHBirthday =
      'Happy Birthday MechaH! I grok thee';

  static const assetDevPortalApk = 'assets/apks/polybius-portal-dev-mechah.apk';

  String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Unlock calendar days: 5 November or 20 April (any year).
  bool isUnlockDay(DateTime day) =>
      (day.month == 11 && day.day == 5) || (day.month == 4 && day.day == 20);

  bool isGunpowderDay(DateTime day) => day.month == 11 && day.day == 5;

  bool isMechaHDay(DateTime day) => day.month == 4 && day.day == 20;

  /// Canonical ritual phrase (for tests / operator docs).
  String ritualPhraseFor(DateTime day) {
    if (isGunpowderDay(day)) return gunpowderRiddle;
    if (isMechaHDay(day)) return mechaHBirthday;
    return '';
  }

  String unlockHintFor(DateTime day) {
    if (isGunpowderDay(day)) {
      return '5 November — hold SAVE NOTE with the Gunpowder Plot riddle…';
    }
    if (isMechaHDay(day)) {
      return '20 April — hold SAVE NOTE with the MechaH birthday line…';
    }
    return 'Note for ${dayKey(day)}';
  }

  /// Normalize text for riddle comparison: letters/digits only, lowercased.
  static String normalizeRitual(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool matchesRitual(String input, DateTime day) {
    if (isGunpowderDay(day)) return _matchesGunpowder(input);
    if (isMechaHDay(day)) return _matchesMechaH(input);
    return false;
  }

  bool _matchesGunpowder(String input) {
    final want = normalizeRitual(gunpowderRiddle);
    var got = normalizeRitual(input);
    if (got.isEmpty) return false;

    got = got
        .replaceAll('fifth', '5th')
        .replaceAll('forgotten', 'forgot')
        .replaceAll('nov ', 'november ');

    if (got == want || got.contains(want)) return true;

    const keys = <String>[
      'remember',
      'remember',
      '5th',
      'november',
      'gunpowder',
      'treason',
      'plot',
      'no',
      'reason',
      'gunpowder',
      'treason',
      'forgot',
    ];
    final tokens = got.split(' ').where((t) => t.isNotEmpty).toList();
    var i = 0;
    for (final t in tokens) {
      if (i < keys.length && t == keys[i]) i++;
    }
    return i >= keys.length;
  }

  bool _matchesMechaH(String input) {
    final want = normalizeRitual(mechaHBirthday);
    final got = normalizeRitual(input);
    if (got.isEmpty) return false;
    if (got == want || got.contains(want)) return true;

    // Fuzzy: happy + birthday + mechah + grok
    const keys = <String>['happy', 'birthday', 'mechah', 'grok'];
    final tokens = got.split(' ').where((t) => t.isNotEmpty).toList();
    var i = 0;
    for (final t in tokens) {
      if (i < keys.length && (t == keys[i] || t.contains(keys[i]))) i++;
    }
    return i >= keys.length;
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
