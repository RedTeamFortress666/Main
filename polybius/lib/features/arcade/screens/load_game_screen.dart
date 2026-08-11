import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/signature_service.dart';
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
      final storage = ref.read(storageServiceProvider);

      // Loading only records the game file number bound to this copy — it
      // never opens the cipher. The crypto engine is reachable solely through
      // the dev access portal login. A signed token is validated before being
      // stored so a bad/expired token is rejected here.
      final token = SignedToken.tryParse(code);
      if (token != null) {
        final trusted = await storage.getTrustedPublicKey();
        final verified =
            await SignatureService(modulusB64: trusted).verifyToken(token);
        if (!verified) {
          if (mounted) setState(() => _message = 'INVALID / EXPIRED FILE');
          return;
        }
        await storage.setActiveToken(code);
        await storage.setGameFileNumber(token.fileNumber);
      } else {
        await storage.setGameFileNumber(code);
      }

      // Prime the portal ritual pathway (diff 11 + ritual language + GAME OVER).
      final bound = await storage.getGameFileNumber() ?? code;
      ref.read(unlockProvider.notifier).onGameFileLoaded(bound);

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
              'Dev codes: ${UnlockCodes.devB1663R} / ${UnlockCodes.devD1663R} / ${UnlockCodes.devW1663R}',
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
