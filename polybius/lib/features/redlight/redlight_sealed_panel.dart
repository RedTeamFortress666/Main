import 'package:flutter/material.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/redlight/redlight_vault.dart';

/// What the ENCRYPT tab shows instead of the glyph keyboard when the
/// red-light vault will not open on this device.
class RedlightSealedPanel extends StatelessWidget {
  const RedlightSealedPanel({super.key, required this.access});

  final RedlightAccess access;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('redlight-sealed'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: NeonTheme.dangerRed, width: 1.4),
        color: NeonTheme.cherryDeep.withValues(alpha: 0.7),
        boxShadow: const [
          BoxShadow(color: NeonTheme.dangerRed, blurRadius: 14, spreadRadius: -6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: NeonTheme.dangerRed, size: 34),
          const SizedBox(height: 8),
          const Text(
            'REDLIGHT SEALED',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
              color: NeonTheme.dangerRed,
              shadows: [Shadow(color: NeonTheme.dangerRed, blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            access.reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 1,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The lamp filter and the phosphor key map are stored in one '
            'AES vault under this device key, bound to the operator on the V2 '
            'ticket. No ticket, no vault — no keyboard.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
