import 'package:flutter/services.dart';

/// Conceals PØLYBĪUS inside the calendar vault.
///
/// User/operator payload: [userPackage].
/// Admin portal (long-press OPEN): [hqPackage].
class PolybiusLauncher {
  static const channel = MethodChannel('doomsday_clock/packages');
  static const userPackage = 'com.polybius.polybius.user';
  static const hqPackage = 'com.polybius.polybius.hq';
  static const activity = 'com.polybius.polybius.MainActivity';

  /// Launch the concealed payload. [hq] is the admin portal.
  static Future<bool> open({bool hq = false}) async {
    try {
      final r = await channel.invokeMethod<bool>('launchPolybius', {
        'package': hq ? hqPackage : userPackage,
        'activity': activity,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isInstalled({bool hq = false}) async {
    try {
      final r = await channel.invokeMethod<bool>('isPackageInstalled', {
        'package': hq ? hqPackage : userPackage,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }
}
