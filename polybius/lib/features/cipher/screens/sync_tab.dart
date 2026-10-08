import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:polybius/core/crypto/unique_qr.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/core/widgets/unique_qr_player.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

/// Share / scan Kyber *public* keys only. Unique QR per share. No seed.
class SyncTab extends ConsumerStatefulWidget {
  const SyncTab({super.key});

  @override
  ConsumerState<SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends ConsumerState<SyncTab> {
  final _assembler = UniqueQrAssembler();
  String? _message;
  bool _ok = false;

  Future<void> _import(String raw) async {
    String candidate = raw;
    if (UniqueQrCodec.isFrame(raw)) {
      final joined = _assembler.add(raw);
      if (joined == null) {
        setState(() {
          _ok = false;
          _message = 'FRAME ${_assembler.seen}';
        });
        return;
      }
      candidate = joined;
      _assembler.reset();
    }
    final token = PoolSync.tryParse(candidate);
    if (token == null || !token.verifyIntegrity()) {
      setState(() {
        _ok = false;
        _message = 'INVALID PUBLIC KEY';
      });
      return;
    }
    if (token.isExpired) {
      setState(() {
        _ok = false;
        _message = 'CODE EXPIRED';
      });
      return;
    }
    await ref.read(storageServiceProvider).setPeerPublicKey(token.publicKey);
    ref.read(peerPublicKeyProvider.notifier).state = token.publicKey;
    _assembler.reset();
    setState(() {
      _ok = true;
      _message = 'PEER ALIGNED — ${token.fingerprint}';
    });
  }

  Future<void> _scan() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanScreen()),
    );
    if (result != null) _import(result);
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(cipherEngineProvider);
    final token = PoolSync.fromPublicKey(engine.keystore.publicKey);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'PUBLIC KEY SHARE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.cherryBright,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Local fp ${engine.keystore.fingerprint}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        UniqueQrPlayer(payload: token.encode()),
        const SizedBox(height: 8),
        const Text(
          'Private key never leaves this device.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const Divider(color: Colors.white24, height: 32),
        ElevatedButton.icon(
          onPressed: _scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('SCAN PEER QR'),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(
            _message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              color: _ok ? NeonTheme.neonGreen : NeonTheme.dangerRed,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScanScreen extends StatelessWidget {
  const _ScanScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('SCAN PEER', style: TextStyle(fontFamily: 'monospace')),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isEmpty) return;
          final value = capture.barcodes.first.rawValue;
          if (value != null) Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
