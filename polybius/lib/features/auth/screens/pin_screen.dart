import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

/// Six-digit PIN re-auth screen (triggered after login when requiresPin).
///
/// Uses an on-screen digit pad so web / iOS PWA entry does not depend on
/// soft-keyboard focus quirks with obscure [TextField]s.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _pin = '';
  String? _error;
  bool _submitting = false;

  Future<void> _submit(String pin) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final ok = await ref.read(authProvider.notifier).verifyPin(pin);
      if (!mounted) return;
      if (ok) {
        context.go('/menu');
      } else {
        final authErr = ref.read(authProvider).error;
        setState(() {
          _error = authErr ?? 'INVALID PIN';
          _pin = '';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'VERIFICATION FAILED — TRY AGAIN';
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onDigit(String d) {
    if (_submitting || _pin.length >= 6) return;
    final next = '$_pin$d';
    setState(() {
      _pin = next;
      _error = null;
    });
    if (next.length == 6) {
      _submit(next);
    }
  }

  void _onBackspace() {
    if (_submitting || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? NeonTheme.neonCyan : Colors.transparent,
                      border: Border.all(color: NeonTheme.neonCyan, width: 2),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: NeonTheme.dangerRed)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: 280,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      _PadKey(
                        label: d,
                        onTap: _submitting ? null : () => _onDigit(d),
                      ),
                    _PadKey(
                      label: '⌫',
                      onTap: _submitting ? null : _onBackspace,
                    ),
                    _PadKey(
                      label: '0',
                      onTap: _submitting ? null : () => _onDigit('0'),
                    ),
                    _PadKey(
                      label: _submitting ? '…' : 'GO',
                      onTap: _submitting || _pin.length != 6
                          ? null
                          : () => _submit(_pin),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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

class _PadKey extends StatelessWidget {
  const _PadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeonButton(
      label: label,
      onPressed: onTap,
    );
  }
}
