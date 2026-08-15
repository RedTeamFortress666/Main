import 'package:flutter/services.dart';

/// Visible CRYPT3X desk apps. Polybius is not listed here.
class CoverApp {
  const CoverApp({
    required this.id,
    required this.label,
    required this.packageName,
    required this.blurb,
  });

  final String id;
  final String label;
  final String packageName;
  final String blurb;
}

class CoverApps {
  static const channel = MethodChannel('doomsday_clock/packages');

  static const mail = CoverApp(
    id: 'mail',
    label: 'MAIL',
    packageName: 'ch.protonmail.android',
    blurb: 'Proton Mail',
  );

  static const fdroid = CoverApp(
    id: 'fdroid',
    label: 'F-DROID',
    packageName: 'org.fdroid.fdroid',
    blurb: 'F-Droid',
  );

  static const brave = CoverApp(
    id: 'brave',
    label: 'BRAVE',
    packageName: 'com.brave.browser',
    blurb: 'Brave',
  );

  /// The only icons on the public home desk.
  static const desk = <CoverApp>[mail, fdroid, brave];

  static Future<bool> isInstalled(String packageName) async {
    try {
      final r = await channel.invokeMethod<bool>('isPackageInstalled', {
        'package': packageName,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> open(String packageName) async {
    try {
      final r = await channel.invokeMethod<bool>('launchPackage', {
        'package': packageName,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }
}
