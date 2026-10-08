import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android screenshot poison: FLAG_SECURE blanks the recents/screenshot buffer.
/// No-op on web and desktop.
class ScreenPoisoner {
  ScreenPoisoner._();

  static const _channel = MethodChannel('polybius/window');

  static Future<void> setSecure(bool secure) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on MissingPluginException {
      // Other targets have no window flag.
    } catch (_) {}
  }
}
