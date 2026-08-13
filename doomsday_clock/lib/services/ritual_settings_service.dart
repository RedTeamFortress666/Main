import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'planner_service.dart';

/// Per-user optional vault unlock phrase + calendar date (defaults still work).
class RitualSettings {
  const RitualSettings({this.phrase, this.month, this.day});

  final String? phrase;
  final int? month;
  final int? day;

  bool get hasCustomPhrase => phrase != null && phrase!.trim().isNotEmpty;
  bool get hasCustomDate => month != null && day != null;

  Map<String, dynamic> toJson() => {
        'phrase': phrase,
        'month': month,
        'day': day,
      };

  factory RitualSettings.fromJson(Map<String, dynamic> j) => RitualSettings(
        phrase: j['phrase'] as String?,
        month: j['month'] as int?,
        day: j['day'] as int?,
      );
}

class RitualSettingsService {
  static const _settingsPrefix = 'ritual_settings_';
  static const _promptedPrefix = 'ritual_prompted_';

  Future<RitualSettings?> load(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_settingsPrefix${username.toUpperCase()}');
    if (raw == null) return null;
    return RitualSettings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
  }

  Future<void> save(String username, RitualSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_settingsPrefix${username.toUpperCase()}',
      jsonEncode(settings.toJson()),
    );
  }

  Future<bool> wasPrompted(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_promptedPrefix${username.toUpperCase()}') ?? false;
  }

  Future<void> markPrompted(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_promptedPrefix${username.toUpperCase()}', true);
  }

  /// Match user ritual: custom date/phrase if set, else Nov 5 / Remember remember.
  bool matchesUnlock(String input, DateTime selectedDay, RitualSettings? custom) {
    final month = custom?.month ?? 11;
    final day = custom?.day ?? 5;
    if (selectedDay.month != month || selectedDay.day != day) {
      return false;
    }

    final phrase = custom?.hasCustomPhrase == true
        ? custom!.phrase!
        : PlannerService.rememberRememberPhrase;

    final got = PlannerService.normalizeRitual(input);
    final want = PlannerService.normalizeRitual(phrase);
    if (got.isEmpty) return false;
    return got == want || got.contains(want);
  }
}
