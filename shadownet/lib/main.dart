import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/shadow_theme.dart';
import 'providers/mesh_providers.dart';
import 'ui/screens/developer_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ShadownetApp()));
}

class ShadownetApp extends ConsumerWidget {
  const ShadownetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  ref.watch(meshControllerProvider);
    return MaterialApp.router(
      title: 'Shadøwnet QShield',
      theme: ShadowTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
