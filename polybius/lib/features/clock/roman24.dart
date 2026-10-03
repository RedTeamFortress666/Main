/// 24-hour Roman numerals for the clock face (I–XXIV).
class Roman24 {
  Roman24._();

  static const List<String> hours = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
    'XIII',
    'XIV',
    'XV',
    'XVI',
    'XVII',
    'XVIII',
    'XIX',
    'XX',
    'XXI',
    'XXII',
    'XXIII',
    'XXIV',
  ];

  /// [hour] is 0–23; midnight is XXIV.
  static String hour(int hour) {
    final h = hour % 24;
    if (h == 0) return hours[23];
    return hours[h - 1];
  }

  static String minute(int minute) => _toRoman(minute.clamp(0, 59));

  static String format(int hour24, int minuteOfHour) =>
      '${hour(hour24)} ${minute(minuteOfHour)}';

  static String _toRoman(int n) {
    if (n == 0) return 'N';
    const pairs = <(int, String)>[
      (50, 'L'),
      (40, 'XL'),
      (10, 'X'),
      (9, 'IX'),
      (5, 'V'),
      (4, 'IV'),
      (1, 'I'),
    ];
    final buf = StringBuffer();
    var rest = n;
    for (final (value, glyph) in pairs) {
      while (rest >= value) {
        buf.write(glyph);
        rest -= value;
      }
    }
    return buf.toString();
  }
}
