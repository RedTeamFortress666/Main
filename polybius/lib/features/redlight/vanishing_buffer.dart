import 'package:polybius/core/constants/app_constants.dart';

/// In-memory plaintext that the UI refuses to keep on screen.
///
/// The secret lives here until [wipe]. The widget layer only ever shows
/// [flash] — the last glyph — and must fade it in under [fadeMs].
class VanishingBuffer {
  VanishingBuffer({this.fadeMs = AppConstants.vanishingMs});

  final int fadeMs;
  final StringBuffer _secret = StringBuffer();
  String _flash = '';
  int _generation = 0;

  String get plaintext => _secret.toString();
  String get flash => _flash;
  int get generation => _generation;
  int get length => _secret.length;
  bool get isEmpty => _secret.isEmpty;

  void append(String ch) {
    if (ch.isEmpty) return;
    _secret.write(ch);
    _flash = ch;
    _generation++;
  }

  void backspace() {
    final s = _secret.toString();
    if (s.isEmpty) {
      _flash = '';
      _generation++;
      return;
    }
    _secret
      ..clear()
      ..write(s.substring(0, s.length - 1));
    _flash = '';
    _generation++;
  }

  String take() {
    final out = _secret.toString();
    wipe();
    return out;
  }

  void wipe() {
    _secret.clear();
    _flash = '';
    _generation++;
  }
}
