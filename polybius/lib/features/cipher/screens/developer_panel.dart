import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/auto_patcher.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/leak_strip.dart';

/// DEVELOPER-only red team sandbox with invite management and pool forcing.
class DeveloperPanel extends ConsumerStatefulWidget {
  const DeveloperPanel({super.key});

  @override
  ConsumerState<DeveloperPanel> createState() => _DeveloperPanelState();
}

class _DeveloperPanelState extends ConsumerState<DeveloperPanel> {
  String? _lastInvite;
  final _pinController = TextEditingController();
  final _pubKeyController = TextEditingController();
  final _coverPinController = TextEditingController();
  final _coverInitialsController = TextEditingController(text: 'CLX');
  final _coverTextController =
      TextEditingController(text: 'HIGH SCORE AT DAWN');
  List<AuditLogEntry> _logs = [];
  List<InviteCode> _invites = [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pubKeyController.dispose();
    _coverPinController.dispose();
    _coverInitialsController.dispose();
    _coverTextController.dispose();
    super.dispose();
  }

  Future<void> _saveTrustedKey() async {
    await ref
        .read(storageServiceProvider)
        .setTrustedPublicKey(_pubKeyController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trusted RSA modulus saved')),
    );
  }

  Future<void> _load() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final logs = await storage.getAuditLogs();
      final invites = await storage.getAllInvites();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _invites = invites;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadError = 'Failed to load panel data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonTheme.background,
      appBar: AppBar(
        backgroundColor: NeonTheme.dangerRed.withValues(alpha: 0.2),
        title: const Text(
          '◈ DEVELOPER ◈',
          style: TextStyle(fontFamily: 'monospace', color: NeonTheme.dangerRed),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _loadError!,
                style: const TextStyle(
                  color: NeonTheme.dangerRed,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          _section('DARTH CHERRY LEAK DETECTOR', [
            LeakStrip(report: ref.watch(leakReportProvider)),
            const SizedBox(height: 8),
            ...ref.watch(leakReportProvider).findings.map(_findingRow),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                ref.read(cabinetPolicyProvider.notifier).weave();
                await ref.read(cherryMixerProvider.notifier).ensure();
                await ref.read(leakSurfaceProvider.notifier).refresh(
                      username: ref.read(authProvider).user?.username,
                    );
                await ref.read(storageServiceProvider).logAudit(
                      AutoPatcher.auditAction,
                      AppConstants.developerUsername,
                      'WOVEN',
                    );
                if (!mounted) return;
                setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: NeonTheme.dangerRed),
              child: const Text('INTERWOVEN AUTOPATCH'),
            ),
          ]),
          _section('INVITE MANAGEMENT', [
            Wrap(
              spacing: 8,
              children: InviteTier.values.map((tier) {
                return ElevatedButton(
                  onPressed: () async {
                    final code = await ref.read(authProvider.notifier).mintInvite(
                          tier,
                          AppConstants.developerUsername,
                        );
                    if (!mounted) return;
                    setState(() => _lastInvite = code);
                    await _load();
                  },
                  child: Text('MINT ${tier.name.toUpperCase()}'),
                );
              }).toList(),
            ),
            if (_lastInvite != null)
              Text(
                'Last: $_lastInvite',
                style: const TextStyle(color: NeonTheme.neonGreen, fontFamily: 'monospace'),
              ),
            ..._invites.take(5).map((i) => ListTile(
                  dense: true,
                  title: Text(i.code, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  subtitle: Text('${i.tier.name} | used: ${i.isUsed}'),
                )),
          ]),
          _section('SIGNING KEY', [
            const Text(
              'The app verifies signed invite tokens against the embedded '
              'RSA public key. Optionally override the trusted modulus for a '
              'per-SD/USB keyset. Tokens are signed OFFLINE with the private '
              'key (never entered in the app) — see tool/polybius_sign.dart.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pubKeyController,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(
                labelText: 'Trusted RSA modulus (base64, optional override)',
                labelStyle: TextStyle(color: NeonTheme.neonCyan, fontSize: 11),
              ),
            ),
            ElevatedButton(
              onPressed: _saveTrustedKey,
              child: const Text('SAVE TRUSTED MODULUS'),
            ),
          ]),
          _section('DARTH CHERRY', [
            const Text(
              'Default ENCRYPT is advanced V1 (plaintext field, 2-glyph engine). '
              'Arming Cherry opens the glyph keyboard, runs the leak detector, '
              'and weaves the auto-patcher. LOAD GAME: DARTH-CHERRY or CH3-RRY.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ARM DARTH CHERRY',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.dangerRed,
                  fontSize: 12,
                ),
              ),
              value: ref.watch(darthCherryProvider),
              activeThumbColor: NeonTheme.dangerRed,
              onChanged: (v) =>
                  ref.read(darthCherryProvider.notifier).setEnabled(v),
            ),
          ]),
          _section('MIDNIGHT CLIMAX CABINET', [
            const Text(
              'Cover PIN looks like a normal checkpoint. Same PIN_OK audit. '
              'Do not use the same digits as the real PIN.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _coverPinController,
              maxLength: 6,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cover PIN (6)',
                labelStyle: TextStyle(color: NeonTheme.neonPink, fontSize: 11),
              ),
            ),
            TextField(
              controller: _coverInitialsController,
              maxLength: 3,
              decoration: const InputDecoration(
                labelText: 'Cover initials',
                labelStyle: TextStyle(color: NeonTheme.neonCyan, fontSize: 11),
              ),
            ),
            TextField(
              controller: _coverTextController,
              decoration: const InputDecoration(
                labelText: 'Cover plaintext (auto-encrypt if field empty)',
                labelStyle: TextStyle(color: NeonTheme.neonGreen, fontSize: 11),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_coverPinController.text.length != 6) return;
                await ref.read(authProvider.notifier).armCabinet(
                      coverPin: _coverPinController.text,
                      initials: _coverInitialsController.text,
                      coverPlaintext: _coverTextController.text,
                    );
                if (!context.mounted) return;
                await ref.read(leakSurfaceProvider.notifier).refresh(
                      username: ref.read(authProvider).user?.username,
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CABINET ARMED')),
                );
              },
              child: const Text('ARM COVER IDENTITY'),
            ),
          ]),
          _section('ADMIN PIN', [
            TextField(
              controller: _pinController,
              maxLength: 6,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New 6-digit PIN',
                labelStyle: TextStyle(color: NeonTheme.neonPink),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_pinController.text.length == 6) {
                  await ref.read(authProvider.notifier).setAdminPin(
                        _pinController.text,
                        AppConstants.developerUsername,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN minted')),
                  );
                }
              },
              child: const Text('MINT ADMIN PIN'),
            ),
          ]),
          _section('OPERATOR CHECKPOINT', [
            const Text(
              'Re-opens the PIN gate without a logout so a cover PIN can be '
              'entered on the DEVELOPER account. Same PIN_OK audit either way.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).requestOperatorCheckpoint();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                context.go('/pin');
              },
              child: const Text('GEAR CAL'),
            ),
          ]),
          _section('POOL FORCING', [
            const Text(
              'Logs out all users, forces 6-digit PIN re-auth, rotates session.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                ref.read(unlockProvider.notifier).reset();
                await ref.read(authProvider.notifier).forcePoolReset(
                      AppConstants.developerUsername,
                    );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pool forced — all users logged out'),
                    backgroundColor: NeonTheme.dangerRed,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: NeonTheme.dangerRed),
              child: const Text('FORCE POOL RESET'),
            ),
          ]),
          _section('AUDIT LOG', [
            ..._logs.take(15).map((l) => ListTile(
                  dense: true,
                  title: Text(
                    l.action,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: NeonTheme.neonCyan,
                    ),
                  ),
                  subtitle: Text(
                    '${l.actor} — ${l.timestamp.toIso8601String().substring(11, 19)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: l.details != null
                      ? Text(l.details!, style: const TextStyle(fontSize: 9))
                      : null,
                )),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: NeonTheme.dangerRed.withValues(alpha: 0.4)),
        color: NeonTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.dangerRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _findingRow(LeakFinding finding) {
    final color = switch (finding.severity) {
      LeakSeverity.open => NeonTheme.dangerRed,
      LeakSeverity.patched => NeonTheme.neonGreen,
      LeakSeverity.residual => NeonTheme.neonYellow,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${finding.severity.name.toUpperCase()}  ${finding.title}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: color,
            ),
          ),
          Text(
            finding.detail,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
