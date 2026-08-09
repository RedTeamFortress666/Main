import 'package:flutter/material.dart';

import '../theme/noir_theme.dart';
import 'bulletin_tab.dart';
import 'clock_tab.dart';
import 'planner_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    BulletinTab(),
    ClockTab(),
    PlannerTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07090C),
              Color(0xFF10151C),
              Color(0xFF0A0E12),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DOOMSDAY CLOCK 2.0',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            color: NoirTheme.cyan,
                            shadows: [
                              Shadow(
                                color: NoirTheme.cyan.withValues(alpha: 0.35),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Neo-noir crisis chronometer',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: NoirTheme.amber,
                            letterSpacing: 2,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _pages[_index]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: NoirTheme.panel,
        indicatorColor: NoirTheme.cyan.withValues(alpha: 0.18),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Bulletin',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Clock',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Planner',
          ),
        ],
      ),
    );
  }
}
