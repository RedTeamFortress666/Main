import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

import 'ritual_settings_service.dart';

/// Daily planner notes + DARTH CHERRY sealed operator cache.
///
/// **5 November** — type `Remember remember` → hold SAVE NOTE 3s → unlocks
/// Gam3.0n operator roster (credentials need DARTH CHERRY filter active).
class PlannerService {
  static const _notesKey = 'planner_notes_v1';

  /// Simple Guy Fawkes phrase (Nov 5 easter egg).
  static const rememberRememberPhrase = 'Remember remember';

  /// MechaH birthday unlock — 20 April (legacy).
  static const mechaHBirthday = 'Happy Birthday MechaH! I grok thee';

  String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool isGunpowderDay(DateTime day) => day.month == 11 && day.day == 5;

  bool isMechaHDay(DateTime day) => day.month == 4 && day.day == 20;

  bool isUnlockDay(DateTime day) => isGunpowderDay(day) || isMechaHDay(day);

  String plannerHintFor(DateTime day) {
    if (isGunpowderDay(day)) {
      return '5 November — planner note…';
    }
    if (isMechaHDay(day)) {
      return '20 April — planner note…';
    }
    return 'Note for ${dayKey(day)}';
  }

  static String normalizeRitual(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool matchesRitual(
    String input,
    DateTime day, {
    RitualSettings? custom,
  }) {
    if (custom != null && (custom.hasCustomDate || custom.hasCustomPhrase)) {
      return RitualSettingsService().matchesUnlock(input, day, custom);
    }
    if (isGunpowderDay(day)) return _matchesRememberRemember(input);
    if (isMechaHDay(day)) return _matchesMechaH(input);
    return false;
  }

  bool _matchesRememberRemember(String input) {
    final got = normalizeRitual(input);
    if (got.isEmpty) return false;
    if (got == 'remember remember' || got.contains('remember remember')) {
      return true;
    }
    // Legacy: full gunpowder riddle still accepted.
    const full =
        'remember remember the 5th of november the gunpowder treason and plot '
        'i know of no reason why gunpowder treason should ever be forgot';
    final want = normalizeRitual(full);
    var normalized = got
        .replaceAll('fifth', '5th')
        .replaceAll('forgotten', 'forgot');
    return normalized == want || normalized.contains(want);
  }

  bool _matchesMechaH(String input) {
    final want = normalizeRitual(mechaHBirthday);
    final got = normalizeRitual(input);
    if (got.isEmpty) return false;
    if (got == want || got.contains(want)) return true;
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

  Future<bool> isCherryCacheOpenForDay(String username, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cherry_cache_${username.toUpperCase()}_${dayKey(day)}';
    return prefs.getBool(key) ?? false;
  }

  Future<void> unlockCherryCacheForDay(String username, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cherry_cache_${username.toUpperCase()}_${dayKey(day)}';
    await prefs.setBool(key, true);
  }

  String newId() =>
      'n_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
}
