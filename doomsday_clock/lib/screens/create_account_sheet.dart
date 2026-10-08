import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/noir_theme.dart';

class CreateAccountSheet extends StatefulWidget {
  const CreateAccountSheet({super.key, required this.auth});

  final AuthService auth;

  static Future<AuthSession?> show(BuildContext context, AuthService auth) {
    return showModalBottomSheet<AuthSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NoirTheme.panel,
      builder: (_) => CreateAccountSheet(auth: auth),
    );
  }

  @override
  State<CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<CreateAccountSheet> {
  final _user = TextEditingController();
  final _display = TextEditingController();
  final _pass = TextEditingController();
  final _pin = TextEditingController();
  String _tier = 'agent';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _user.dispose();
    _display.dispose();
    _pass.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = await widget.auth.registerLocalAccount(
      username: _user.text,
      displayName: _display.text,
      password: _pass.text,
      pin: _pin.text,
      tier: _tier,
    );
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _busy = false;
        _error = 'Could not create account — username taken or invalid';
      });
      return;
    }
    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CREATE VAULT ACCOUNT',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: NoirTheme.neonMagenta,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _user,
              decoration: const InputDecoration(
                labelText: 'USERNAME',
                labelStyle: TextStyle(color: NoirTheme.neonCyan),
              ),
              style: const TextStyle(color: NoirTheme.mist),
            ),
            TextField(
              controller: _display,
              decoration: const InputDecoration(
                labelText: 'DISPLAY NAME',
                labelStyle: TextStyle(color: NoirTheme.neonCyan),
              ),
              style: const TextStyle(color: NoirTheme.mist),
            ),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PASSWORD',
                labelStyle: TextStyle(color: NoirTheme.neonCyan),
              ),
              style: const TextStyle(color: NoirTheme.mist),
            ),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '6-DIGIT PIN',
                labelStyle: TextStyle(color: NoirTheme.neonCyan),
              ),
              style: const TextStyle(color: NoirTheme.mist),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _tier,
              dropdownColor: NoirTheme.panel,
              decoration: const InputDecoration(
                labelText: 'TIER',
                labelStyle: TextStyle(color: NoirTheme.neonCyan),
              ),
              items: const [
                DropdownMenuItem(value: 'agent', child: Text('agent')),
                DropdownMenuItem(value: 'admin', child: Text('admin')),
                DropdownMenuItem(value: 'developer', child: Text('developer')),
              ],
              onChanged: _busy ? null : (v) => setState(() => _tier = v ?? 'agent'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _submit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: NoirTheme.neonMagenta,
                  side: const BorderSide(color: NoirTheme.neonMagenta),
                ),
                child: Text(_busy ? 'CREATING…' : 'CREATE ACCOUNT'),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: NoirTheme.crimson)),
              ),
          ],
        ),
      ),
    );
  }
}
