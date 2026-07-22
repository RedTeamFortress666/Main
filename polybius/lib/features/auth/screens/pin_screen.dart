import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

/// Six-digit PIN re-auth screen (triggered by pool forcing / admin actions).
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref.read(authProvider.notifier).verifyPin(_pinController.text);
    if (!mounted) return;
    if (ok) {
      context.go('/menu');
    } else {
      setState(() => _error = 'INVALID PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 64, color: NeonTheme.neonPink),
              const SizedBox(height: 24),
              Text(
                'SECURITY CHECKPOINT',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter 6-digit operator PIN',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pinController,
                  maxLength: 6,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    letterSpacing: 12,
                    color: NeonTheme.neonCyan,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: NeonTheme.neonCyan),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: NeonTheme.dangerRed)),
              ],
              const SizedBox(height: 24),
              NeonButton(label: 'VERIFY', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
