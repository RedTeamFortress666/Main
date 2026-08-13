import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/auth/widgets/operator_identity_card.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

/// Operator identity cards.
///
/// Full roster: SpamKat2 / RedTeam01 / Gam3.0n only.
/// All other accounts see only their own card.
class OperatorCardsScreen extends ConsumerStatefulWidget {
  const OperatorCardsScreen({super.key});

  @override
  ConsumerState<OperatorCardsScreen> createState() =>
      _OperatorCardsScreenState();
}

class _OperatorCardsScreenState extends ConsumerState<OperatorCardsScreen> {
  VeilNotifier? _veil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _veil = ref.read(veilProvider.notifier);
      _veil?.startWatching();
    });
  }

  @override
  void dispose() {
    // Cipher shell may still be watching — leave poll running if already open.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final veil = ref.watch(veilProvider);
    final auth = ref.watch(authProvider);
    final secrets = veil.filterActive;
    final username = auth.user?.username;
    final fullRoster = OperatorIdentities.canViewFullRoster(username);
    final cards = OperatorIdentities.visibleFor(username);

    return Scaffold(
      backgroundColor: NeonTheme.background,
      appBar: AppBar(
        backgroundColor: NeonTheme.surface,
        title: Text(
          fullRoster ? '◈ OPERATOR ROSTER ◈' : '◈ YOUR OPERATOR CARD ◈',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: secrets
                ? const Color(0x33FF0040)
                : const Color(0x2200FF66),
            child: Text(
              secrets
                  ? (fullRoster
                      ? 'DARTH CHERRY ACTIVE — roster credentials exposed'
                      : 'DARTH CHERRY ACTIVE — your credentials exposed')
                  : (fullRoster
                      ? 'DEV ROSTER — eye · callsign · invite (full list)'
                      : 'YOUR CARD — eye · callsign · invite only'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: secrets ? NeonTheme.dangerRed : NeonTheme.neonGreen,
              ),
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? const Center(
                    child: Text(
                      'NO OPERATOR CARD BOUND TO THIS LOGIN',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cards.length,
                    itemBuilder: (context, i) => OperatorIdentityCard(
                      identity: cards[i],
                      secretsUnlocked: secrets,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
