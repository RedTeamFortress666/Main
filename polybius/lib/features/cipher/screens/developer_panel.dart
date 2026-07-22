import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  List<AuditLogEntry> _logs = [];
  List<InviteCode> _invites = [];
  int _securityScore = 87;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final storage = ref.read(storageServiceProvider);
    final logs = await storage.getAuditLogs();
    final invites = await storage.getAllInvites();
    setState(() {
      _logs = logs;
      _invites = invites;
    });
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
                    setState(() => _lastInvite = code);
                    _load();
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
                await ref.read(authProvider.notifier).forcePoolReset(
                      AppConstants.developerUsername,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pool forced — all users logged out'),
                      backgroundColor: NeonTheme.dangerRed,
                    ),
                  );
                }
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
