import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/matrix_chrome.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onAuthenticated});

  final void Function(AuthSession session, {required bool needsVaultSetup})
      onAuthenticated;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  Future<void> _tryRestore() async {
    final s = await _auth.currentSession();
    if (s == null || !mounted) return;
    final needs = await _auth.needsVaultSetup(s.username);
    widget.onAuthenticated(s, needsVaultSetup: needs);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = await _auth.login(
      username: _user.text,
      password: _pass.text,
      pin: _pin.text,
    );
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _busy = false;
        _error = 'ACCESS DENIED — Polybius developer/admin only';
      });
      return;
    }
    final needs = await _auth.needsVaultSetup(session.username);
    if (needs) {
      await _auth.seedUserVault(session.username);
    }
    HapticFeedback.mediumImpact();
    widget.onAuthenticated(session, needsVaultSetup: needs);
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MatrixRainBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'DOOMSDAY CLOCK 2.0',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      shadows: [
                        Shadow(
                          color: NoirTheme.matrix.withValues(alpha: 0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'VAULT LOGIN · POLYBIUS DEVELOPER / ADMIN',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: NoirTheme.pink,
                    ),
              ),
              const SizedBox(height: 24),
              NeonPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: _user,
                      style: const TextStyle(color: NoirTheme.mist),
                      decoration: const InputDecoration(
                        labelText: 'USERNAME',
                        labelStyle: TextStyle(color: NoirTheme.matrix),
                      ),
                    ),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      style: const TextStyle(color: NoirTheme.mist),
                      decoration: const InputDecoration(
                        labelText: 'PASSWORD / BACKUP',
                        labelStyle: TextStyle(color: NoirTheme.matrix),
                      ),
                    ),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: NoirTheme.mist),
                      decoration: const InputDecoration(
                        labelText: '6-DIGIT PIN',
                        labelStyle: TextStyle(color: NoirTheme.matrix),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _submit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NoirTheme.matrix,
                          side: const BorderSide(color: NoirTheme.matrix),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_busy ? 'AUTH…' : 'OPEN TERMINAL'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: NoirTheme.crimson)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Same credentials as Polybius developers & admins. '
                'First login seeds a personal vault for this operator.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NoirTheme.mist.withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VaultSetupScreen extends StatefulWidget {
  const VaultSetupScreen({
    super.key,
    required this.session,
    required this.onDone,
  });

  final AuthSession session;
  final VoidCallback onDone;

  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

class _VaultSetupScreenState extends State<VaultSetupScreen> {
  final _auth = AuthService();
  bool _done = false;

  Future<void> _finish() async {
    await _auth.seedUserVault(widget.session.username);
    await _auth.markVaultSetupComplete(widget.session.username);
    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return MatrixRainBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: NeonPanel(
              color: NoirTheme.pink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIRST LOGIN · VAULT SETUP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: NoirTheme.pink,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Operator ${widget.session.displayName} (${widget.session.tier})',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Seeding personal vault:\n'
                    '• PØLYBĪUS Admin APK slot\n'
                    '• DARTH CHERRY companion slot\n'
                    '• GRØK-REBEL 6.0 alarm interface hook\n\n'
                    'Ritual notes still unlock daily vault view in Planner.',
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _done ? null : _finish,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: NoirTheme.matrix,
                        side: const BorderSide(color: NoirTheme.matrix),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_done ? 'VAULT ARMED' : 'INITIALIZE VAULT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
