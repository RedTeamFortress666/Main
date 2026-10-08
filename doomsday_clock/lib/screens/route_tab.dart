import 'package:flutter/material.dart';

import '../services/cover_apps.dart';
import '../services/route_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';

/// DNS, IP path, and fingerprint toggles. Defaults are Android 11-safe.
class RouteTab extends StatefulWidget {
  const RouteTab({super.key});

  @override
  State<RouteTab> createState() => _RouteTabState();
}

class _RouteTabState extends State<RouteTab> {
  RouteStatus _status = RouteService.fallback;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await RouteService.status();
    if (!mounted) return;
    setState(() => _status = s);
  }

  Future<void> _run(Future<bool> Function() op, String fail) async {
    setState(() => _busy = true);
    final ok = await op();
    await _reload();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fail)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('ROUTE · DNS / IP / PRINT',
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          'Android 11 Private DNS is DoT. Brave Shields handle canvas, '
          'fonts, and WebRTC. Swap resolvers without a flash.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.55),
              ),
        ),
        const SizedBox(height: 12),
        NeonPanel(
          color: s.hardened ? NoirTheme.peace : NoirTheme.amber,
          child: Text(
            s.hardened
                ? 'PROFILE · HARDENED'
                : 'PROFILE · ADAPT — apply to lock DNS + print',
            style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(
                    RouteService.applyHardenedProfile,
                    'Need privileged vault (WRITE_SECURE_SETTINGS).',
                  ),
          style: OutlinedButton.styleFrom(foregroundColor: NoirTheme.matrix),
          child: Text(_busy ? 'APPLYING…' : 'APPLY 2026 HARDENED PROFILE'),
        ),
        const SizedBox(height: 18),
        Text('DNS · PRIVATE (DoT)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          'Now: ${s.dnsMode}${s.dnsHost.isEmpty ? '' : ' · ${s.dnsHost}'}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ...RouteService.presets.map((p) {
          final active = s.dnsMode == p.mode &&
              (p.hostname == null || s.dnsHost == p.hostname);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: _busy ? null : () => _run(() => RouteService.applyDns(p), 'DNS write failed.'),
              child: NeonPanel(
                color: active ? NoirTheme.peace : NoirTheme.matrix,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.label,
                        style: const TextStyle(
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800,
                        )),
                    Text(p.blurb, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Text('IP · PATH', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(
          s.vpnPackage.isEmpty
              ? 'Clearnet. Drop Orbot or WireGuard for a device-wide path.'
              : 'VPN · ${s.vpnPackage}${s.vpnLockdown ? ' · LOCKDOWN' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        _pathButton('ORBOT · TOR VPN', RouteService.orbotPackage),
        _pathButton('WIREGUARD · YOUR KEYS', RouteService.wireguardPackage),
        _pathButton('BRAVE · SHIELDS', RouteService.bravePackage),
        const SizedBox(height: 14),
        Text('PRINT · FINGERPRINT', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _flag('Random Wi-Fi MAC', s.macRandom, 'macRandom'),
        _flag('No always-on Wi-Fi scan', !s.wifiScanAlways, 'wifiScanOff'),
        _flag('No always-on BLE scan', !s.bleScanAlways, 'bleScanOff'),
        _flag('Location off', s.locationOff, 'locationOff'),
        _flag('Skip captive-portal phoning home', s.captivePortalOff, 'captiveOff'),
        const SizedBox(height: 8),
        Text(
          'Brave as default browser: ${s.browserRole.isEmpty ? 'not held' : s.browserRole}. '
          'In Brave: Shields up, fingerprinting blocked, WebRTC leak shield, '
          'HTTPS only, no Google Safe Browsing if you can turn it off.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NoirTheme.mist.withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }

  Widget _pathButton(String label, String package) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: _busy
            ? null
            : () async {
                final ok = await CoverApps.open(package);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label not installed.')),
                  );
                }
              },
        style: OutlinedButton.styleFrom(foregroundColor: NoirTheme.cyan),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }

  Widget _flag(String label, bool on, String key) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: on,
      activeThumbColor: NoirTheme.matrix,
      onChanged: _busy
          ? null
          : (v) => _run(() => RouteService.setFlag(key, v), 'Flag write failed.'),
    );
  }
}
