import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/operator_card.dart';
import '../services/qr_card_codec.dart';
import '../theme/noir_theme.dart';

class QrShareSheet extends StatelessWidget {
  const QrShareSheet({super.key, required this.card});

  final OperatorCard card;

  static Future<void> show(BuildContext context, OperatorCard card) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: NoirTheme.panel,
      isScrollControlled: true,
      builder: (_) => QrShareSheet(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = QrCardCodec.encodePolybiusCard(
      username: card.username,
      displayName: card.displayName,
      tier: card.tier,
      inviteCode: card.inviteCode,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.username,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: NoirTheme.neonMagenta,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: NoirTheme.chrome,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
