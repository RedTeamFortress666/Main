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
import 'package:polybius/features/glasses/cover_screensaver.dart';
import 'package:polybius/features/glasses/glasses_link.dart';
import 'package:polybius/features/redlight/cabinet_lamp.dart';

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

  @override
  Widget build(BuildContext context) {
    final unlock = ref.watch(unlockProvider);
    final isDev = unlock.state == UnlockState.developer;
    final cherry = ref.watch(darthCherryProvider);
    final access = ref.watch(redlightAccessProvider).valueOrNull;
    final vaultOpen = access?.granted ?? false;
    // The lamp is a vault property: no open vault, no filter — and the
    // matrix itself comes out of the sealed profile, not a compiled constant.
    final lamp = cherry && vaultOpen && ref.watch(cabinetLampProvider);
    final policy = ref.watch(cabinetPolicyProvider);
    final viewer = ref.watch(glassesViewerProvider);
    final attract = policy.glassesHud && viewer != GlassesViewer.hud;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cherry ? NeonTheme.cherryDeep : NeonTheme.surface,
        title: Text(
          cherry ? '◈ DΛRTH CHERRY CHANNEL ◈' : '◈ CIPHER CHANNEL ◈',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            color: cherry ? NeonTheme.cherry : Colors.white,
            shadows: cherry
                ? const [Shadow(color: NeonTheme.dangerRed, blurRadius: 12)]
                : null,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeonTheme.neonCyan),
          onPressed: () => context.go('/menu'),
        ),
        actions: [
          if (cherry)
            IconButton(
              icon: Icon(
                lamp ? Icons.lightbulb : Icons.lightbulb_outline,
                color: !vaultOpen
                    ? Colors.white24
                    : lamp
                        ? NeonTheme.dangerRed
                        : NeonTheme.neonYellow,
              ),
              tooltip: !vaultOpen
                  ? 'Redlight sealed — ${access?.reason ?? 'opening vault'}'
                  : lamp
                      ? 'Cabinet lamp'
                      : 'House lights',
              onPressed: !vaultOpen
                  ? null
                  : () => ref.read(cabinetLampProvider.notifier).state = !lamp,
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeveloperPanel()),
                );
              },
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
      body: CabinetLamp.wrap(
        on: lamp,
        filter: access?.profile?.lampFilter,
        child: Stack(
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
            if (attract)
              CoverScreensaver(
                canWake: ref.watch(authProvider).isAuthenticated,
                onOperatorWake: () {
                  ref.read(glassesViewerProvider.notifier).state =
                      GlassesViewer.hud;
                },
              ),
          ],
        ),
      ),
    );
  }
}
