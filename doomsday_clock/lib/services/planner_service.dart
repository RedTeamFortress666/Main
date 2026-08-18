import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/planner_note.dart';

class PlannerService {
  PlannerService({this.holdMs = defaultHoldMs});

  static const notesKey = 'journal_notes_v1';
  static const archiveOpenKey = 'journal_archive_open_v1';
  static const defaultHoldMs = 3000;

  static const unlockMonth = 11;
  static const unlockDay = 5;

  final int holdMs;

  String dayKey([DateTime? day]) {
    final d = day ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool isUnlockDay(DateTime day) =>
      day.month == unlockMonth && day.day == unlockDay;

  static String normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool matchesUnlockPhrase(String input) {
    final got = normalize(input);
    if (got.isEmpty) return false;
    if (got == 'remember remember' || got.contains('remember remember')) {
      return true;
    }
    const full =
        'remember remember the 5th of november the gunpowder treason and plot '
        'i know of no reason why gunpowder treason should ever be forgot';
    final want = normalize(full);
    final normalized = got.replaceAll('fifth', '5th').replaceAll('forgotten', 'forgot');
    return normalized == want || normalized.contains(want);
  }

  bool matchesUnlockRitual(String input, DateTime day) =>
      isUnlockDay(day) && matchesUnlockPhrase(input);

  Future<List<PlannerNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(notesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PlannerNote.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveNotes(List<PlannerNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      notesKey,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<bool> isArchiveOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(archiveOpenKey) ?? false;
  }

  Future<void> openArchive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(archiveOpenKey, true);
  }

  String newId() =>
      'n_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
}
