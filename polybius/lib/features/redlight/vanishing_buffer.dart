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
  int? _lastAppendMs;
  final List<int> _gapsMs = [];

  String get plaintext => _secret.toString();
  String get flash => _flash;
  int get generation => _generation;
  int get length => _secret.length;
  bool get isEmpty => _secret.isEmpty;

  /// Inter-keypress gaps only. Never the glyphs.
  List<int> get gapsMs => List<int>.unmodifiable(_gapsMs);

  void append(String ch) {
    if (ch.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastAppendMs != null) {
      _gapsMs.add(now - _lastAppendMs!);
    }
    _lastAppendMs = now;
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
    _lastAppendMs = null;
    _gapsMs.clear();
    _generation++;
  }
}
