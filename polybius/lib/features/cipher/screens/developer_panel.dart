import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/models/models.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';

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
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  List<AuditLogEntry> _logs = [];
  List<InviteCode> _invites = [];
  int _securityScore = 87;
  String? _loadError;
  String? _valkyrieReveal;

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(authProvider).user?.name ?? '';
    _load();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pubKeyController.dispose();
    _nameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changeName() async {
    await ref.read(authProvider.notifier).setDisplayName(_nameController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Operator name updated')));
  }

  Future<void> _changePassword() async {
    final err = await ref
        .read(authProvider.notifier)
        .changePassword(_newPasswordController.text);
    if (!mounted) return;
    _newPasswordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Password changed')),
    );
  }

  Future<void> _runValkyrie() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeonTheme.surface,
        title: const Text('⚠ OPERATION VALKYRIE ⚠',
            style: TextStyle(
                fontFamily: 'monospace', color: NeonTheme.dangerRed)),
        content: const Text(
          'Wipes network state (invites, audit, sessions, all non-developer '
          'accounts), rotates to a fresh pool at MAXIMUM complexity (6), sets a '
          '2-hour rotation window, and reveals the admin recovery bundle. '
          'This cannot be undone. Proceed?',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ABORT')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('EXECUTE',
                  style: TextStyle(color: NeonTheme.dangerRed))),
        ],
      ),
    );
    if (confirmed != true) return;

    final storage = ref.read(storageServiceProvider);
    await storage.wipeNetworkState();
    await storage.setPoolWindowHours(2);
    ref.read(unlockProvider.notifier).reset();
    ref.read(poolSeedProvider.notifier).randomise();
    ref.read(cipherComplexityProvider.notifier).setComplexity(6);
    await storage.logAudit('VALKYRIE', AppConstants.developerUsername,
        'Network wiped; max complexity; 2h window');

    final poolId = ref.read(cipherEngineProvider).poolId;
    if (!mounted) return;
    setState(() {
      _valkyrieReveal =
          'RECOVERY BUNDLE (authorised admins only):\n'
          'New pool ID $poolId · complexity 6 · 2h window.\n'
          'Directive: re-establish the network from this pool, re-issue admin '
          'invites (B1/D1), rotate keys, and distribute the SYNC code from the '
          'cipher SYNC tab to trusted admins to realign.';
    });
    await _load();
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
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/menu'),
            icon: const Icon(Icons.exit_to_app,
                color: NeonTheme.neonYellow, size: 18),
            label: const Text('EXIT TO ARCADE',
                style: TextStyle(
                    color: NeonTheme.neonYellow,
                    fontFamily: 'monospace',
                    fontSize: 11)),
          ),
        ],
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
          _section('RED TEAM SANDBOX', [
            _scoreBar('Security Score', _securityScore),
            _scoreBar('Cover Integrity', 94),
            _scoreBar('Cipher Strength', 91),
            ElevatedButton(
              onPressed: () => setState(() => _securityScore = 50 + (DateTime.now().millisecond % 50)),
              style: ElevatedButton.styleFrom(backgroundColor: NeonTheme.dangerRed),
              child: const Text('RUN PENETRATION SCAN'),
            ),
          ]),
          _section('OPERATOR', [
            TextField(
              controller: _nameController,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'Operator name',
                labelStyle: TextStyle(color: NeonTheme.neonCyan),
              ),
            ),
            ElevatedButton(
                onPressed: _changeName, child: const Text('CHANGE NAME')),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'New password',
                labelStyle: TextStyle(color: NeonTheme.neonPink),
              ),
            ),
            ElevatedButton(
                onPressed: _changePassword,
                child: const Text('CHANGE PASSWORD')),
          ]),
          _section('CIPHER COMPLEXITY', [
            Consumer(builder: (context, ref, _) {
              final complexity = ref.watch(cipherComplexityProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$complexity emojis per character',
                      style: const TextStyle(
                          color: NeonTheme.neonGreen, fontFamily: 'monospace')),
                  Slider(
                    value: complexity.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '$complexity',
                    onChanged: (v) => ref
                        .read(cipherComplexityProvider.notifier)
                        .setComplexity(v.round()),
                  ),
                ],
              );
            }),
          ]),
          _section('OPERATION VALKYRIE', [
            const Text(
              'Fail-safe for a rogue developer: wipe + restart the network, '
              'dial rotor complexity to maximum, switch to a 2-hour pool '
              'rotation, and reveal the admin recovery bundle.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _runValkyrie,
              style:
                  ElevatedButton.styleFrom(backgroundColor: NeonTheme.dangerRed),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('ENGAGE VALKYRIE'),
            ),
            if (_valkyrieReveal != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SelectableText(
                  _valkyrieReveal!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonGreen,
                    fontSize: 11,
                  ),
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

  Widget _scoreBar(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white12,
              color: score > 80
                  ? NeonTheme.neonGreen
                  : score > 50
                      ? NeonTheme.neonYellow
                      : NeonTheme.dangerRed,
            ),
          ),
          const SizedBox(width: 8),
          Text('$score%', style: const TextStyle(fontSize: 11, color: NeonTheme.neonGreen)),
        ],
      ),
    );
  }
}
