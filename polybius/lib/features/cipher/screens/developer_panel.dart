import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/leak_detector.dart';
import 'package:polybius/features/redlight/leak_strip.dart';
import 'package:polybius/features/redlight/patch_ledger.dart';

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
  bool _weaving = false;
  String _vetLine = 'NO RECEIPT';
  String _tableLine = 'NO REPORT';

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
      final receipt = await storage.getLastReceipt();
      final report = await storage.getLastPatternReport();
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _invites = invites;
        _loadError = null;
        _vetLine = receipt == null
            ? 'NO RECEIPT — notes never land in Hive'
            : '${receipt.readout} · ${receipt.origin} · fp ${receipt.fingerprintPrefix}';
        _tableLine = report == null
            ? 'NO REPORT'
            : '${report.readout} · ${report.boil} · interfered=${report.interfered}';
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
          ]),
          _section('INTERWOVEN AUTOPATCH', [
            const Text(
              'DETECT → APPLY → VERIFY → LEDGER. Every trigger (LOGIN, RESTORE, '
              'CHERRY, SYNC, MANUAL) runs the same pipeline and chains one '
              'entry under the device key. Policy patches, not binary patches.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            _ledgerHeader(ref.watch(autoPatcherProvider)),
            const SizedBox(height: 6),
            ...ref
                .watch(autoPatcherProvider)
                .entries
                .reversed
                .take(6)
                .map(_ledgerRow),
            if (ref.watch(autoPatcherProvider).latest != null) ...[
              const SizedBox(height: 8),
              const Text(
                'LAST WEAVE — STEP OUTCOMES',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: NeonTheme.neonCyan,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              ...ref
                  .watch(autoPatcherProvider)
                  .latest!
                  .results
                  .map(_patchResultRow),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _weaving
                        ? null
                        : () async {
                            setState(() => _weaving = true);
                            final entry = await ref
                                .read(autoPatcherProvider.notifier)
                                .weave('MANUAL');
                            await _load();
                            if (!mounted) return;
                            setState(() => _weaving = false);
                            if (entry == null || !context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'WOVEN ${entry.readout} · ${entry.appliedCount} APPLIED · ${entry.heldCount} HELD',
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeonTheme.dangerRed,
                    ),
                    child: Text(_weaving ? 'WEAVING…' : 'RUN WEAVE'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(autoPatcherProvider.notifier)
                        .reset(AppConstants.developerUsername);
                    await _load();
                  },
                  child: const Text('RESET LEDGER'),
                ),
              ],
            ),
          ]),
          _section('CABINET MESH', [
            const Text(
              'ML-KEM-768 hybrid, stego vet, round table, glasses HUD. '
              'The developer panel sees receipts and boiled cadence reports — '
              'not plaintext, not decoy runes, not sidecar analyst notes. '
              'The table does not drop human-to-human frames.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Text(
              'VET  $_vetLine',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: NeonTheme.neonYellow,
              ),
            ),
            Text(
              'TABLE  $_tableLine',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: NeonTheme.neonGreen,
              ),
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
              'and triggers a CHERRY weave in the ledger. LOAD GAME: DARTH-CHERRY or CH3-RRY.',
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

  Widget _ledgerHeader(PatchLedger ledger) {
    final color = ledger.intact ? NeonTheme.neonGreen : NeonTheme.dangerRed;
    final latest = ledger.latest;
    return Text(
      ledger.isEmpty
          ? 'LEDGER EMPTY — first weave records the compiled baseline'
          : 'CHAIN ${ledger.intact ? 'INTACT' : 'BROKEN'} · ${ledger.entries.length} ENTRIES · LAST ${latest!.readout} · MAC ${latest.mac.length >= 8 ? latest.mac.substring(0, 8) : latest.mac}',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        color: color,
        shadows: [Shadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
      ),
    );
  }

  Widget _ledgerRow(PatchLedgerEntry entry) {
    final stamp = entry.at.toIso8601String().substring(11, 19);
    final color =
        entry.openAfter == 0 ? NeonTheme.neonCyan : NeonTheme.neonYellow;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.readout,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: color),
            ),
          ),
          Text(
            '${entry.appliedCount}A ${entry.heldCount}H ${entry.pendingCount}P ${entry.residualCount}R',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${stamp}Z',
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _patchResultRow(PatchResult result) {
    final color = switch (result.outcome) {
      PatchOutcome.applied => NeonTheme.neonGreen,
      PatchOutcome.held => NeonTheme.neonCyan,
      PatchOutcome.pending => NeonTheme.dangerRed,
      PatchOutcome.residual => NeonTheme.neonYellow,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${result.outcome.name.toUpperCase().padRight(8)} ${result.title}  ${result.before.name}→${result.after.name}',
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: color),
          ),
          Text(
            result.action,
            style: const TextStyle(color: Colors.white38, fontSize: 9),
          ),
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
