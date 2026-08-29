import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';
import 'package:polybius/features/cipher/screens/clipboard_row.dart';

/// Pool sync: randomise the hidden mapping and share/scan a QR so two users
/// align on the same pool + rotor configuration.
class SyncTab extends ConsumerStatefulWidget {
  const SyncTab({super.key});

  @override
  ConsumerState<SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends ConsumerState<SyncTab> {
  final _pasteController = TextEditingController();
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _import(String raw) {
    final token = PoolSync.tryParse(raw);
    if (token == null) {
      setState(() {
        _ok = false;
        _message = 'INVALID SYNC CODE';
      });
      return;
    }
    if (token.isExpired) {
      setState(() {
        _ok = false;
        _message = 'CODE EXPIRED — REQUEST A FRESH POOL';
      });
      return;
    }
    if (!token.verifyIntegrity()) {
      setState(() {
        _ok = false;
        _message = 'INTEGRITY CHECK FAILED';
      });
      return;
    }
    ref.read(poolSeedProvider.notifier).setSeed(token.seed);
    setState(() {
      _ok = true;
      _message = 'POOL ALIGNED — ${token.poolId}';
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
    final seed = ref.watch(poolSeedProvider);
    final engine = ref.watch(cipherEngineProvider);
    final token = PoolSync.fromSeed(seed);
    final code = token.encode();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'POOL SYNC',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            color: NeonTheme.neonCyan,
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Active pool: ${ref.watch(displayPoolIdProvider)} · slot ${engine.slot}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(poolSeedProvider.notifier).randomise();
            setState(() {
              _ok = true;
              _message = 'NEW POOL GENERATED — SHARE TO ALIGN';
            });
          },
          icon: const Icon(Icons.casino),
          label: const Text('RANDOMISE POOL'),
        ),
        const SizedBox(height: 20),
        const Text(
          'SHARE THIS POOL',
          style: TextStyle(color: NeonTheme.neonGreen, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: QrImageView(
              data: code,
              version: QrVersions.auto,
              size: 200,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Valid ${token.expiresAt.difference(DateTime.now()).inHours}h · scan or share the code',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        SelectableText(
          code,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: Colors.white38,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipboardRow(
              color: NeonTheme.neonCyan,
              getCopyText: () => code,
              onPaste: _import,
            ),
            TextButton.icon(
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: code)),
              icon: const Icon(Icons.ios_share,
                  color: NeonTheme.neonCyan, size: 18),
              label: const Text('SHARE',
                  style: TextStyle(color: NeonTheme.neonCyan)),
            ),
          ],
        ),
        const Divider(color: Colors.white24, height: 32),
        const Text(
          'ALIGN WITH ANOTHER USER',
          style: TextStyle(color: NeonTheme.neonPink, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('SCAN QR'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pasteController,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          decoration: const InputDecoration(
            labelText: 'or paste a sync code',
            labelStyle: TextStyle(color: NeonTheme.neonPink, fontSize: 12),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _import(_pasteController.text.trim()),
          child: const Text('IMPORT CODE'),
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
        title: const Text('SCAN POOL QR',
            style: TextStyle(fontFamily: 'monospace')),
        leading: IconButton(
          icon: const Icon(Icons.close, color: NeonTheme.neonCyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
