import 'package:flutter/services.dart';

/// Android 11 Private DNS (DoT) presets. Swap without flashing.
class DnsPreset {
  const DnsPreset({
    required this.id,
    required this.label,
    required this.mode,
    this.hostname,
    required this.blurb,
  });

  final String id;
  final String label;
  /// `off` | `opportunistic` | `hostname`
  final String mode;
  final String? hostname;
  final String blurb;
}

class RouteStatus {
  const RouteStatus({
    required this.dnsMode,
    required this.dnsHost,
    required this.macRandom,
    required this.wifiScanAlways,
    required this.bleScanAlways,
    required this.locationOff,
    required this.captivePortalOff,
    required this.vpnPackage,
    required this.vpnLockdown,
    required this.browserRole,
  });

  final String dnsMode;
  final String dnsHost;
  final bool macRandom;
  final bool wifiScanAlways;
  final bool bleScanAlways;
  final bool locationOff;
  final bool captivePortalOff;
  final String vpnPackage;
  final bool vpnLockdown;
  final String browserRole;

  bool get hardened =>
      dnsMode == 'hostname' &&
      macRandom &&
      !wifiScanAlways &&
      !bleScanAlways &&
      locationOff &&
      captivePortalOff;
}

/// DNS / IP path / fingerprint controls for the CRYPT3X desk.
class RouteService {
  static const channel = MethodChannel('doomsday_clock/packages');

  static const presets = <DnsPreset>[
    DnsPreset(
      id: 'quad9',
      label: 'QUAD9',
      mode: 'hostname',
      hostname: 'dns.quad9.net',
      blurb: 'DoT · malware sinkhole · no-log',
    ),
    DnsPreset(
      id: 'mullvad',
      label: 'MULLVAD',
      mode: 'hostname',
      hostname: 'dns.mullvad.net',
      blurb: 'DoT · no-log · no filter',
    ),
    DnsPreset(
      id: 'mullvad-ad',
      label: 'MULLVAD AD',
      mode: 'hostname',
      hostname: 'adblock.dns.mullvad.net',
      blurb: 'DoT · ads/trackers filtered',
    ),
    DnsPreset(
      id: 'proton',
      label: 'PROTON',
      mode: 'hostname',
      hostname: 'dns.proton.me',
      blurb: 'DoT · Proton resolver',
    ),
    DnsPreset(
      id: 'opportunistic',
      label: 'AUTO TLS',
      mode: 'opportunistic',
      blurb: 'Upgrade when the resolver speaks TLS',
    ),
    DnsPreset(
      id: 'off',
      label: 'CLEAR',
      mode: 'off',
      blurb: 'ISP resolver — avoid on hostile nets',
    ),
  ];

  static const orbotPackage = 'org.torproject.android';
  static const wireguardPackage = 'com.wireguard.android';
  static const bravePackage = 'com.brave.browser';

  static Future<RouteStatus> status() async {
    try {
      final raw = await channel.invokeMethod<Map<Object?, Object?>>('routeStatus');
      if (raw == null) return fallback;
      return RouteStatus(
        dnsMode: (raw['dnsMode'] as String?) ?? 'off',
        dnsHost: (raw['dnsHost'] as String?) ?? '',
        macRandom: raw['macRandom'] == true,
        wifiScanAlways: raw['wifiScanAlways'] == true,
        bleScanAlways: raw['bleScanAlways'] == true,
        locationOff: raw['locationOff'] == true,
        captivePortalOff: raw['captivePortalOff'] == true,
        vpnPackage: (raw['vpnPackage'] as String?) ?? '',
        vpnLockdown: raw['vpnLockdown'] == true,
        browserRole: (raw['browserRole'] as String?) ?? '',
      );
    } catch (_) {
      return fallback;
    }
  }

  static Future<bool> applyDns(DnsPreset preset) async {
    try {
      final r = await channel.invokeMethod<bool>('setPrivateDns', {
        'mode': preset.mode,
        'hostname': preset.hostname ?? '',
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> applyHardenedProfile() async {
    try {
      final r = await channel.invokeMethod<bool>('applyHardenedProfile');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setFlag(String key, bool value) async {
    try {
      final r = await channel.invokeMethod<bool>('setRouteFlag', {
        'key': key,
        'value': value,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  static const fallback = RouteStatus(
    dnsMode: 'hostname',
    dnsHost: 'dns.quad9.net',
    macRandom: true,
    wifiScanAlways: false,
    bleScanAlways: false,
    locationOff: true,
    captivePortalOff: true,
    vpnPackage: '',
    vpnLockdown: false,
    browserRole: '',
  );
}
