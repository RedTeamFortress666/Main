import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/noir_theme.dart';
import '../widgets/doomsday_logo.dart';
import '../widgets/matrix_chrome.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.onAuthenticated});

  final void Function(AuthSession session) onAuthenticated;

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
    widget.onAuthenticated(s);
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
        _error = 'ACCESS DENIED — developer / admin only';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onAuthenticated(session);
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
              const Center(child: DoomsdayLogo(size: 140)),
              const SizedBox(height: 18),
              Text(
                'CYBER TERMINAL · OPERATOR AUTH',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 24),
              NeonPanel(
                color: NoirTheme.neonMagenta,
                child: Column(
                  children: [
                    TextField(
                      controller: _user,
                      style: const TextStyle(color: NoirTheme.mist),
                      decoration: const InputDecoration(
                        labelText: 'USERNAME',
                        labelStyle: TextStyle(color: NoirTheme.neonCyan),
                      ),
                    ),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      style: const TextStyle(color: NoirTheme.mist),
                      decoration: const InputDecoration(
                        labelText: 'PASSWORD / BACKUP',
                        labelStyle: TextStyle(color: NoirTheme.neonCyan),
                      ),
                    ),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: NoirTheme.mist),
                      decoration: const InputDecoration(
                        labelText: '6-DIGIT PIN',
                        labelStyle: TextStyle(color: NoirTheme.neonCyan),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _busy ? null : _submit,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NoirTheme.neonMagenta,
                          side: const BorderSide(color: NoirTheme.neonMagenta),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_busy ? 'AUTH…' : 'JACK IN'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: NoirTheme.crimson),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Privileged PØLYBÎŪS operators only. '
                'DARTH CHERRY sealed data unlocks in Planner on 5 November.',
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
