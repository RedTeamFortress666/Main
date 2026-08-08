import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';

/// Username + password account creation (user tier).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = 'PASSWORDS DO NOT MATCH');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await ref
        .read(authProvider.notifier)
        .register(_username.text, _password.text);
    if (!mounted) return;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ACCOUNT CREATED — LOG IN')),
      );
      context.go('/login');
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArcadeScaffold(
      accent: NeonTheme.neonCyan,
      showFooter: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const ArcadeTitle(fontSize: 30),
                  const SizedBox(height: 8),
                  const Text(
                    'CREATE OPERATOR ACCOUNT',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: NeonTheme.neonCyan,
                      letterSpacing: 3,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _field('OPERATOR ID', _username),
                  const SizedBox(height: 14),
                  _field('ACCESS KEY', _password, obscure: true),
                  const SizedBox(height: 14),
                  _field('CONFIRM ACCESS KEY', _confirm, obscure: true),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!,
                        style: const TextStyle(
                            color: NeonTheme.dangerRed,
                            fontFamily: 'monospace',
                            letterSpacing: 1)),
                  ],
                  const SizedBox(height: 24),
                  ArcadeMenuButton(
                    label: _busy ? 'CREATING...' : 'CREATE ACCOUNT',
                    color: NeonTheme.neonGreen,
                    onPressed: _busy ? null : _submit,
                  ),
                  ArcadeMenuButton(
                    label: 'BACK TO LOGIN',
                    color: NeonTheme.neonPink,
                    dense: true,
                    onPressed: _busy ? null : () => context.go('/login'),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: NeonTheme.neonGreen,
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        ArcadeField(
          controller: controller,
          obscure: obscure,
          textAlign: TextAlign.left,
          fontSize: 16,
          letterSpacing: 1,
          textColor: Colors.white,
        ),
      ],
    );
  }
}
