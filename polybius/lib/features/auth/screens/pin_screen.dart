import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';
import 'package:polybius/features/duress/duress_session.dart';

/// Six-digit PIN re-auth screen (triggered by pool forcing / admin actions).
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final pin = _pinController.text;
      final ok = await ref.read(authProvider.notifier).verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        final auth = ref.read(authProvider);
        if (auth.coverArmed && auth.user != null) {
          final cabinet = await ref
              .read(storageServiceProvider)
              .getCabinet(auth.user!.username);
          if (cabinet != null) {
            ref.read(duressProvider.notifier).arm(
                  DuressSession.arm(
                    cabinet: cabinet,
                    realSeed: ref.read(poolSeedProvider),
                    pin: pin,
                  ),
                );
          }
        } else {
          ref.read(duressProvider.notifier).disarm();
        }
        if (!mounted) return;
        context.go('/menu');
      } else {
        setState(() => _error = 'INVALID PIN');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'VERIFICATION FAILED — TRY AGAIN');
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                  enabled: !_submitting,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: NeonTheme.dangerRed)),
              ],
              const SizedBox(height: 24),
              NeonButton(
                label: _submitting ? 'VERIFYING...' : 'VERIFY',
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted || !context.mounted) return;
                  context.go('/login');
                },
                child: const Text(
                  'SIGN OUT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
