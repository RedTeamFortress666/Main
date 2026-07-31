import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';

/// "Load game file number" — the user enters their dev-generated invite code.
/// Confirming stores the file number and returns to the start screen; the
/// hidden cipher pathway is opened later via the ritual sequence, not here.
class LoadGameScreen extends ConsumerStatefulWidget {
  const LoadGameScreen({super.key});

  @override
  ConsumerState<LoadGameScreen> createState() => _LoadGameScreenState();
}

class _LoadGameScreenState extends ConsumerState<LoadGameScreen> {
  final _codeController = TextEditingController();
  String? _message;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_loading) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final settings = ref.read(gameSettingsProvider);
      final auth = ref.read(authProvider);
      await ref.read(unlockProvider.notifier).checkInviteCode(
            code,
            settings,
            auth.user?.tier,
          );
      await ref.read(storageServiceProvider).setGameFileNumber(code);

      if (!mounted) return;
      setState(() => _message = 'SAVE FILE LOADED');
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => _message = 'READ ERROR — TRY AGAIN');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArcadeScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
        children: [
          const Spacer(),
          const ArcadeTitle(),
          const SizedBox(height: 28),
          const Text(
            'LOAD GAME - ENTER GAME FILE NUMBER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.neonCyan,
              letterSpacing: 2,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ArcadeField(
            controller: _codeController,
            hint: 'XXX-XXX-XXX',
            enabled: !_loading,
            onSubmitted: (_) => _confirm(),
          ),
          const SizedBox(height: 24),
          ArcadeMenuButton(
            label: _loading ? 'LOADING...' : 'CONFIRM',
            color: NeonTheme.neonGreen,
            onPressed: _loading ? null : _confirm,
          ),
          ArcadeMenuButton(
            label: 'BACK',
            color: NeonTheme.neonPink,
            dense: true,
            onPressed: _loading ? null : () => context.pop(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: TextStyle(
                fontFamily: 'monospace',
                color: _message == 'SAVE FILE LOADED'
                    ? NeonTheme.neonGreen
                    : NeonTheme.dangerRed,
                letterSpacing: 2,
              ),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            Text(
              'Dev codes: ${UnlockCodes.devB1663R} / ${UnlockCodes.devD1663R}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
          const Spacer(),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
