import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'polybius_operators.dart';

/// Factory-reset PIN. Entering it on the vault lock wipes userdata.
///
/// Looks like a failed login, then CRYPT3X returns to first-boot.
class DuressService {
  static const channel = MethodChannel('doomsday_clock/packages');
  static const prefsKey = 'crypt3x_duress_pin';

  /// Factory default for the lite test image. Change at first vault setup.
  /// Must not collide with any operator PIN.
  static const defaultPin = '737380';

  static bool looksLikePin(String raw) =>
      RegExp(r'^\d{6}$').hasMatch(raw.trim());

  static bool conflictsWithOperatorPin(String pin) {
    final p = pin.trim();
    return polybiusPrivilegedOperators.any((op) => op.pin == p);
  }

  Future<String> currentPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKey) ?? defaultPin;
  }

  Future<bool> matches(String pin) async {
    if (!looksLikePin(pin)) return false;
    return pin.trim() == await currentPin();
  }

  /// Returns an error string if [pin] cannot be stored.
  Future<String?> setPin(String pin) async {
    final p = pin.trim();
    if (!looksLikePin(p)) return 'Duress PIN must be 6 digits.';
    if (conflictsWithOperatorPin(p)) {
      return 'Choose a PIN that is not an operator PIN.';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, p);
    return null;
  }

  /// Wipe vault state, then ask the system for a factory reset.
  /// On web / unprivileged builds this only clears local prefs.
  Future<DuressResult> triggerReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      final r = await channel.invokeMethod<bool>('factoryReset');
      if (r == true) return DuressResult.systemWipe;
    } catch (_) {}
    return DuressResult.localWipe;
  }
}

enum DuressResult { systemWipe, localWipe }
