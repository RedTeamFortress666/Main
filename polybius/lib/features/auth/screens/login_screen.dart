import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

/// Replit-style OIDC login gate. First install ships with DEVELOPER account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(authProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (ok) {
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

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0221),
                  Color(0xFF1A0533),
                  Color(0xFF0A1628),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CLASSIFIED ARCADE TERMINAL',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: NeonTheme.neonGreen,
                          ),
                    ),
                    const SizedBox(height: 40),
                    _LoginField(
                      controller: _usernameController,
                      label: 'OPERATOR ID',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: NeonButton(
                        label: auth.isLoading ? 'AUTHENTICATING...' : 'LOGIN',
                        onPressed: auth.isLoading ? null : _submit,
                        color: NeonTheme.neonPink,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'First install: use DEVELOPER / developer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: Colors.white38,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
