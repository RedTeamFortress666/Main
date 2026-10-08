import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Haptic + system click so the operator can type without watching the
/// vanishing glyph. Failures are swallowed — a silent cabinet still encrypts.
class Keyclick {
  static Future<void> tick({bool audio = true, bool haptic = true}) async {
    try {
      if (haptic) {
        await HapticFeedback.selectionClick();
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Haptic cabinet dark: $error');
    }
    if (!audio) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (error) {
      if (kDebugMode) debugPrint('Click cabinet dark: $error');
    }
  }
}
