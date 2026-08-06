import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Layer 3 hidden cipher tool — accessible only after unlock rituals.
class CipherShell extends ConsumerStatefulWidget {
  const CipherShell({super.key});

  @override
  ConsumerState<CipherShell> createState() => _CipherShellState();
}

class _CipherShellState extends ConsumerState<CipherShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
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
    final isDev = unlock.state == UnlockState.developer;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: NeonTheme.surface,
        title: const Text(
          '◈ CIPHER CHANNEL ◈',
          style: TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeonTheme.neonCyan),
          onPressed: () => context.go('/menu'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/menu'),
            icon: const Icon(Icons.exit_to_app, color: NeonTheme.neonYellow, size: 18),
            label: const Text('EXIT TO ARCADE',
                style: TextStyle(
                    color: NeonTheme.neonYellow,
                    fontFamily: 'monospace',
                    fontSize: 11)),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: NeonTheme.neonPink),
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
          indicatorColor: NeonTheme.neonCyan,
          labelColor: NeonTheme.neonCyan,
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          EncryptTab(),
          DecryptTab(),
          PoolTab(),
          SyncTab(),
          ConnectTab(),
        ],
      ),
    );
  }
}
