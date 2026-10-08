import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/clock/clock_session.dart';

/// Clock lock. Factory code is `oneeyedking`; first unlock asks for a new code.
class ClockGateScreen extends ConsumerStatefulWidget {
  const ClockGateScreen({super.key});

  @override
  ConsumerState<ClockGateScreen> createState() => _ClockGateScreenState();
}

class _ClockGateScreenState extends ConsumerState<ClockGateScreen> {
  final _password = TextEditingController();
  final _next = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await ref.read(clockSessionProvider.notifier).unlock(_password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    final session = ref.read(clockSessionProvider);
    if (err == null && !session.mustChangePassword) {
      context.go('/clock/face');
    }
  }

  Future<void> _change() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err =
        await ref.read(clockSessionProvider.notifier).changePassword(_next.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) context.go('/clock/face');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(clockSessionProvider);
    final changing = session.unlocked && session.mustChangePassword;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, color: Color(0xFFC9A227), size: 48),
                const SizedBox(height: 12),
                const Text(
                  'CLOCK',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    letterSpacing: 8,
                    color: Color(0xFFC9A227),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  changing ? 'CHOOSE A NEW CODE' : 'ENTER CODE',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white54,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 24),
                if (!changing)
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onSubmitted: (_) => _unlock(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: NeonTheme.neonCyan,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'CODE',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  )
                else
                  TextField(
                    controller: _next,
                    obscureText: true,
                    onSubmitted: (_) => _change(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: NeonTheme.neonCyan,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'NEW CODE',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: NeonTheme.dangerRed)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : (changing ? _change : _unlock),
                    child: Text(changing ? 'SAVE CODE' : 'OPEN'),
                  ),
                ),
                if (kDebugMode && !changing) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Factory code: oneeyedking',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
