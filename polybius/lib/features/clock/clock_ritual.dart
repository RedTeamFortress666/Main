/// Timing and face positions used by the clock / Cherry desk.
///
/// Public copy never names a concealed compartment — these are clock
/// operations (set face, set alarm, cherry glass, notes).
class ClockRitual {
  ClockRitual._();

  static const int analogHour = 5;
  static const int analogMinute = 11;
  static const String alarmLegend = 'V XIXI';
  static const String factoryPassword = 'oneeyedking';

  static const Duration setAlarmHold = Duration(seconds: 3);
  static const Duration makeHold = Duration(seconds: 2);
  static const Duration vanishDelay = Duration(milliseconds: 800);
  static const Duration eternityHold = Duration(seconds: 2);

  static String normalizeAlarm(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool alarmMatches(String raw) => normalizeAlarm(raw) == alarmLegend;

  static bool analogMatches(int hour, int minute) =>
      hour == analogHour && minute == analogMinute;

  static bool canOpenDesk({
    required int hour,
    required int minute,
    required String alarm,
    required bool cherryActive,
  }) =>
      analogMatches(hour, minute) &&
      alarmMatches(alarm) &&
      cherryActive;
}
