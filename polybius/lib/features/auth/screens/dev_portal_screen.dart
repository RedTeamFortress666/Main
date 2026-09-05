import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';

/// Portal is reachable only when the router sees [pathwayPrimed] (or an
/// already-unlocked cipher). Access is the operator passphrase — never a
/// compiled-in code.
class DevPortalScreen extends ConsumerStatefulWidget {
  const DevPortalScreen({super.key});

  @override
  ConsumerState<DevPortalScreen> createState() => _DevPortalScreenState();
}

class _DevPortalScreenState extends ConsumerState<DevPortalScreen> {
  final _pass = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider);
      final user = auth.user;
      if (user == null) {
        setState(() => _error = 'ACCESS DENIED');
        return;
      }
      final pass = _pass.text;
      if (user.portalPassHash == null) {
        final err =
            await ref.read(authProvider.notifier).setPortalPassphrase(pass);
        if (err != null) {
          setState(() => _error = err);
          return;
        }
      } else if (!ref.read(authProvider.notifier).verifyPortalPassphrase(pass)) {
        setState(() => _error = 'ACCESS DENIED');
        return;
      }

      final privileged =
          user.tier == UserTier.developer || user.tier == UserTier.admin;
      if (privileged) {
        ref.read(unlockProvider.notifier).grantDeveloperAccess();
      } else {
        ref.read(unlockProvider.notifier).grantUserAccess();
      }
      if (mounted) context.go('/cipher');
    } catch (_) {
      if (mounted) setState(() => _error = 'ACCESS DENIED');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final first = user?.portalPassHash == null;
    return ArcadeScaffold(
      accent: NeonTheme.cherryBright,
      showFooter: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),
                  const Text(
                    'DARTH CHERRY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      color: NeonTheme.cherryBright,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'v3 ACCESS PORTAL',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: NeonTheme.cherryGold,
                      letterSpacing: 4,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    first
                        ? 'SET PORTAL PASSPHRASE (${AppConstants.minPasswordLength}+)'
                        : 'PORTAL PASSPHRASE',
                    style: const TextStyle(
                      color: NeonTheme.neonGreen,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ArcadeField(
                    controller: _pass,
                    obscure: true,
                    textAlign: TextAlign.left,
                    fontSize: 16,
                    letterSpacing: 1,
                    color: NeonTheme.cherryBright,
                    textColor: Colors.white,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!,
                        style: const TextStyle(
                            color: NeonTheme.dangerRed,
                            fontFamily: 'monospace',
                            letterSpacing: 2)),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ArcadeMenuButton(
                          label: 'CANCEL',
                          color: NeonTheme.neonPink,
                          dense: true,
                          onPressed: _busy ? null : () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ArcadeMenuButton(
                          label: _busy ? '...' : (first ? 'SET + OPEN' : 'OPEN'),
                          color: NeonTheme.neonGreen,
                          dense: true,
                          onPressed: _busy ? null : _login,
                        ),
                      ),
                    ],
                  ),
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
