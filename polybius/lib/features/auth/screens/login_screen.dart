import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';
import 'package:polybius/core/widgets/cabinet_atmosphere.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';
import 'package:polybius/features/auth/v2_login_protocol.dart';
import 'package:polybius/features/auth/widgets/v2_protocol_console.dart';

/// V2 protocol login gate. First install ships with DEVELOPER account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  int _visibleLines = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _visibleLines = 0);
    final ok = await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
          deferCommit: true,
        );
    if (!mounted) return;
    final handshake = ref.read(authProvider).handshake;
    for (var i = 1; i <= handshake.lines.length; i++) {
      if (!mounted) return;
      setState(() => _visibleLines = i);
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    if (!mounted) return;
    if (ok) {
      // Hold the finished console for a beat, then publish the account.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      ref.read(authProvider.notifier).commitLogin();
      final auth = ref.read(authProvider);
      if (auth.needsPin) {
        context.go('/pin');
      } else {
        context.go('/menu');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return ArcadeScaffold(
      child: CabinetAtmosphere(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ArcadeTitle(fontSize: 40),
                  const SizedBox(height: 6),
                  Text(
                    '${V2LoginProtocol.name}  PROTOCOL',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: NeonTheme.neonGreen,
                          letterSpacing: 3,
                          shadows: const [
                            Shadow(color: NeonTheme.neonGreen, blurRadius: 12),
                          ],
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'CHALLENGE · VERIFY · TICKET · SWEEP · PATCH · CABINET',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      letterSpacing: 1,
                      color: Colors.white38,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _LoginField(
                    controller: _usernameController,
                    label: 'OPERATOR ID',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _LoginField(
                    controller: _passwordController,
                    label: 'ACCESS KEY',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: NeonTheme.neonCyan,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      auth.error!,
                      style: const TextStyle(color: NeonTheme.dangerRed),
                    ),
                  ],
                  const SizedBox(height: 14),
                  V2ProtocolConsole(
                    log: auth.handshake,
                    visibleLines: auth.handshake.lines.isEmpty
                        ? null
                        : _visibleLines,
                    preview: auth.handshake.lines.isEmpty,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      label: auth.isLoading ? 'AUTHENTICATING...' : 'LOGIN',
                      onPressed: auth.isLoading ? null : _submit,
                      color: NeonTheme.neonPink,
                    ),
                  ),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () => context.go('/register'),
                    child: const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: NeonTheme.neonCyan,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      'First install: use DEVELOPER / developer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        fontFamily: 'monospace',
        color: NeonTheme.neonCyan,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: NeonTheme.neonGreen),
        prefixIcon: Icon(icon, color: NeonTheme.neonCyan),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.45),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: NeonTheme.neonCyan),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: NeonTheme.neonPink, width: 2),
        ),
      ),
    );
  }
}
