import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/pool_view_gate.dart';

/// Daily emoji pool — grid is gated behind game file number + 6-digit PIN
/// so the 560-glyph mapping cannot be casually screenshot / leaked. Encrypt,
/// decrypt, and QR sync stay available without unlocking this view.
class PoolTab extends ConsumerStatefulWidget {
  const PoolTab({super.key});

  @override
  ConsumerState<PoolTab> createState() => _PoolTabState();
}

class _PoolTabState extends ConsumerState<PoolTab> {
  final _fileController = TextEditingController();
  final _pinController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _fileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(poolViewGateProvider.notifier).unlock(
            gameFileNumber: _fileController.text,
            pin: _pinController.text,
          );
      if (mounted && ref.read(poolViewGateProvider).unlocked) {
        _pinController.clear();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(poolViewGateProvider);
    if (!gate.unlocked) {
      return _PoolLockGate(
        fileController: _fileController,
        pinController: _pinController,
        error: gate.error,
        busy: _busy,
        onUnlock: _unlock,
      );
    }

    final engine = ref.watch(cipherEngineProvider);
    final pool = engine.pool;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE POOL — ${engine.poolId}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: NeonTheme.neonCyan,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pool.length} / ${AppConstants.poolSize} emojis · cleared for session',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => ref.read(poolViewGateProvider.notifier).lock(),
                child: const Text(
                  'LOCK',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.neonPink,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
            ),
            itemCount: pool.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: index < AppConstants.halfPool
                        ? NeonTheme.neonCyan.withValues(alpha: 0.3)
                        : NeonTheme.neonPink.withValues(alpha: 0.3),
                  ),
                  color: NeonTheme.surface,
                ),
                child: Center(
                  child: Text(
                    pool[index],
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PoolLockGate extends StatelessWidget {
  const _PoolLockGate({
    required this.fileController,
    required this.pinController,
    required this.onUnlock,
    this.error,
    this.busy = false,
  });

  final TextEditingController fileController;
  final TextEditingController pinController;
  final VoidCallback onUnlock;
  final String? error;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0028), Color(0xFF050510), Color(0xFF001820)],
            ),
            border: Border.all(color: NeonTheme.neonPink.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: NeonTheme.neonPink.withValues(alpha: 0.18),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.visibility_off, color: NeonTheme.neonPink, size: 42),
              const SizedBox(height: 12),
              const Text(
                'POOL VAULT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonCyan,
                  fontSize: 18,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The 560-emoji mapping stays hidden. Enter your game file number and 6-digit PIN to view. Encrypt, decrypt, and QR sync still work without opening the vault.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: fileController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonGreen,
                  letterSpacing: 1.5,
                ),
                decoration: const InputDecoration(
                  labelText: 'GAME FILE NUMBER',
                  labelStyle: TextStyle(color: NeonTheme.neonCyan, fontSize: 12),
                  prefixIcon: Icon(Icons.folder_special_outlined,
                      color: NeonTheme.neonCyan),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onUnlock(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: NeonTheme.neonPink,
                  fontSize: 22,
                  letterSpacing: 10,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: '6-DIGIT PIN',
                  labelStyle: TextStyle(color: NeonTheme.neonPink, fontSize: 12),
                  prefixIcon: Icon(Icons.pin, color: NeonTheme.neonPink),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onUnlock(),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: NeonTheme.dangerRed,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: busy ? null : onUnlock,
                icon: const Icon(Icons.lock_open),
                label: Text(busy ? 'VERIFYING…' : 'UNLOCK POOL VIEW'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: NeonTheme.neonCyan,
                  side: const BorderSide(color: NeonTheme.neonCyan, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
