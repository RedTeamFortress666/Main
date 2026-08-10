import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:polybius/core/constants/app_flavor.dart';
import 'package:polybius/core/constants/unlock_codes.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/theme/neon_theme.dart';
import 'package:polybius/features/cipher/screens/connect_tab.dart';
import 'package:polybius/features/cipher/screens/decrypt_tab.dart';
import 'package:polybius/features/cipher/screens/developer_panel.dart';
import 'package:polybius/features/cipher/screens/encrypt_tab.dart';
import 'package:polybius/features/cipher/screens/pool_tab.dart';
import 'package:polybius/features/cipher/screens/rotor_gear_sheet.dart';
import 'package:polybius/features/cipher/screens/sync_tab.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

/// Layer 3 hidden cipher tool — accessible only after unlock rituals.
class CipherShell extends ConsumerStatefulWidget {
  const CipherShell({super.key});

  @override
  ConsumerState<CipherShell> createState() => _CipherShellState();
}

class _CipherShellState extends ConsumerState<CipherShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VeilNotifier? _veil;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // Watch for the RED VEIL companion beacon while the cipher is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _veil = ref.read(veilProvider.notifier);
      _veil?.startWatching();
    });
  }

  @override
  void dispose() {
    _veil?.stopWatching();
    _tabController.dispose();
    super.dispose();
  }

  void _showRotorGear() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeonTheme.surface,
      builder: (_) => const RotorGearSheet(),
    );
  }

  Future<void> _openDeveloperPanel() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NeonTheme.surface,
        title: const Text('DEV ACCESS',
            style: TextStyle(fontFamily: 'monospace', color: NeonTheme.dangerRed)),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (_) => Navigator.of(dialogContext).pop(
            ref.read(authProvider.notifier).verifyCurrentPassword(controller.text),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              ref
                  .read(authProvider.notifier)
                  .verifyCurrentPassword(controller.text),
            ),
            child: const Text('ENTER'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (ok == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DeveloperPanel()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ACCESS DENIED')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlock = ref.watch(unlockProvider);
    final isDev =
        AppFlavor.allowDeveloperTools && unlock.state == UnlockState.developer;
    final veil = ref.watch(veilProvider);
    final matrix = veil.mode == VeilMode.matrix;

    return Scaffold(
      backgroundColor: matrix ? const Color(0xFF020A04) : null,
      appBar: AppBar(
        backgroundColor: matrix ? const Color(0xFF031A08) : NeonTheme.surface,
        title: Text(
          matrix
              ? '◈ MATRIX VEIL ◈'
              : (AppFlavor.isHq ? '◈ EMOJINIGMA HQ ◈' : '◈ CIPHER CHANNEL ◈'),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            color: matrix ? const Color(0xFF00FF66) : null,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: matrix ? const Color(0xFF00FF66) : NeonTheme.neonCyan),
          onPressed: () => context.go('/menu'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/menu'),
            icon: Icon(Icons.exit_to_app,
                color: matrix ? const Color(0xFF00FF66) : NeonTheme.neonYellow,
                size: 18),
            label: Text('EXIT TO ARCADE',
                style: TextStyle(
                    color: matrix
                        ? const Color(0xFF00FF66)
                        : NeonTheme.neonYellow,
                    fontFamily: 'monospace',
                    fontSize: 11)),
          ),
          IconButton(
            icon: Icon(Icons.settings,
                color: matrix ? const Color(0xFF00FF66) : NeonTheme.neonPink),
            tooltip: 'Rotor Gear',
            onPressed: _showRotorGear,
          ),
          if (isDev)
            IconButton(
              icon: const Icon(Icons.bug_report, color: NeonTheme.dangerRed),
              tooltip: 'Developer Panel',
              onPressed: _openDeveloperPanel,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor:
              matrix ? const Color(0xFF00FF66) : NeonTheme.neonCyan,
          labelColor: matrix ? const Color(0xFF00FF66) : NeonTheme.neonCyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          isScrollable: true,
          tabs: const [
            Tab(text: '🔒 ENCRYPT'),
            Tab(text: '🔓 DECRYPT'),
            Tab(text: '🎲 POOL'),
            Tab(text: '🔗 SYNC'),
            Tab(text: '📡 CONNECT'),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          TabBarView(
            controller: _tabController,
            children: const [
              EncryptTab(),
              DecryptTab(),
              PoolTab(),
              SyncTab(),
              ConnectTab(),
            ],
          ),
          if (matrix)
            IgnorePointer(
              child: CustomPaint(painter: _MatrixRainPainter()),
            ),
        ],
      ),
    );
  }
}

/// Subtle falling green code rain while matrix veil is engaged.
class _MatrixRainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x2200FF66);
    const cols = 18;
    final colW = size.width / cols;
    for (var c = 0; c < cols; c++) {
      final x = c * colW + colW * 0.4;
      for (var r = 0; r < 12; r++) {
        final y = (r * 48.0 + c * 17) % (size.height + 40);
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 10), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
