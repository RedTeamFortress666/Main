import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/crypto/signature_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/arcade_ui.dart';

enum _Grant { none, user, developer }

/// POLYBIUS dev access portal — reached via the ritual sequence
/// (title hold -> difficulty 11 -> Russian hold-to-select). This is the ONLY
/// entry to the crypto engine: a valid account login plus an access code
/// (B1-66-3R / D1-66-3R / W1-66-3R for dev, Tr1-66-3R for user/admin, or a
/// signed invite token).
class DevPortalScreen extends ConsumerStatefulWidget {
  const DevPortalScreen({super.key});

  @override
  ConsumerState<DevPortalScreen> createState() => _DevPortalScreenState();
}

class _DevPortalScreenState extends ConsumerState<DevPortalScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _devCode = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _devCode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final storage = ref.read(storageServiceProvider);
      final rawCode = _devCode.text.trim();
      final code = rawCode.toUpperCase();

      // A valid account login is always required.
      final ok = await ref
          .read(authProvider.notifier)
          .login(_username.text.trim(), _password.text);
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = 'ACCESS DENIED');
        return;
      }

      final tier = ref.read(authProvider).user?.tier;
      final privileged =
          tier == UserTier.developer || tier == UserTier.admin;

      // Resolve which access the supplied code grants.
      //   B1-66-3R / D1-66-3R / W1-66-3R -> developer (requires privileged account)
      //   Tr1-66-3R -> user-only for agents; full engine for admin/developer
      //   signed invite token -> tier per token (dev needs privileged account)
      _Grant grant = _Grant.none;
      if (UnlockCodes.developerCodes.contains(code)) {
        if (privileged) grant = _Grant.developer;
      } else if (code == UnlockCodes.userTr1663R) {
        grant = privileged ? _Grant.developer : _Grant.user;
      } else {
        final token = SignedToken.tryParse(rawCode);
        if (token != null) {
          final trusted = await storage.getTrustedPublicKey();
          final verified =
              await SignatureService(modulusB64: trusted).verifyToken(token);
          if (verified) {
            final devTier =
                token.tier == 'developer' || token.tier == 'admin';
            grant = (devTier && privileged) ? _Grant.developer : _Grant.user;
          }
        }
      }

      switch (grant) {
        case _Grant.developer:
          ref.read(unlockProvider.notifier).grantDeveloperAccess();
          if (mounted) context.go('/cipher');
        case _Grant.user:
          ref.read(unlockProvider.notifier).grantUserAccess();
          if (mounted) context.go('/cipher');
        case _Grant.none:
          setState(() => _error = 'ACCESS DENIED');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'ACCESS DENIED');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArcadeScaffold(
      accent: NeonTheme.dangerRed,
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
            'PØLYBĪUS',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              color: NeonTheme.neonPink,
              letterSpacing: 6,
              shadows: [Shadow(color: NeonTheme.neonCyan, blurRadius: 16)],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'DEV ACCESS PORTAL',
            style: TextStyle(
              fontFamily: 'monospace',
              color: NeonTheme.dangerRed,
              letterSpacing: 4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          _labelled('USERNAME', _username),
          const SizedBox(height: 14),
          _labelled('PASSWORD', _password, obscure: true),
          const SizedBox(height: 14),
          _labelled('DEV CODE', _devCode),
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
                  label: _busy ? '...' : 'LOG IN?',
                  color: NeonTheme.neonGreen,
                  dense: true,
                  onPressed: _busy ? null : _login,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'UNAUTHORISED ACCESS IS A CRIMINAL OFFENCE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
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

  Widget _labelled(String label, TextEditingController controller,
      {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: NeonTheme.neonGreen,
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        ArcadeField(
          controller: controller,
          obscure: obscure,
          textAlign: TextAlign.left,
          fontSize: 16,
          letterSpacing: 1,
          color: NeonTheme.neonCyan,
          textColor: Colors.white,
        ),
      ],
    );
  }
}
