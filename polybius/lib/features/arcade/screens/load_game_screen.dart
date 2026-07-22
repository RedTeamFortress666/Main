import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/crt_widgets.dart';

/// "Load game file number" — disguised invite code entry for cipher unlock.
class LoadGameScreen extends ConsumerStatefulWidget {
  const LoadGameScreen({super.key});

  @override
  ConsumerState<LoadGameScreen> createState() => _LoadGameScreenState();
}

class _LoadGameScreenState extends ConsumerState<LoadGameScreen> {
  final _codeController = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final settings = ref.read(gameSettingsProvider);
    final auth = ref.read(authProvider);

    await ref.read(unlockProvider.notifier).checkInviteCode(
          code,
          settings,
          auth.user?.tier,
        );

    final unlock = ref.read(unlockProvider);

    if (unlock.state.index >= UnlockState.unlocked.index) {
      setState(() => _message = 'SAVE FILE LOADED');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/cipher');
    } else {
      setState(() => _message = 'FILE NOT FOUND');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('LOAD GAME', style: TextStyle(fontFamily: 'monospace')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeonTheme.neonCyan),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text(
              'ENTER GAME FILE NUMBER',
              style: TextStyle(
                fontFamily: 'monospace',
                color: NeonTheme.neonGreen,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 24,
                color: NeonTheme.neonCyan,
                letterSpacing: 4,
              ),
              decoration: const InputDecoration(
                hintText: 'PB-XXXXXXXX',
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: NeonTheme.neonCyan),
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: _message == 'SAVE FILE LOADED'
                      ? NeonTheme.neonGreen
                      : NeonTheme.dangerRed,
                ),
              ),
            ],
            const SizedBox(height: 32),
            NeonButton(label: 'LOAD', onPressed: _load, color: NeonTheme.neonGreen),
            if (kDebugMode) ...[
              const Spacer(),
              Text(
                'Dev codes: ${UnlockCodes.devB1663R} / ${UnlockCodes.devD1663R}\n'
                'Requires CHINESE language in settings',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
