import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/app.dart';
import 'package:polybius/core/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(encryptionServiceProvider).init();
  await container.read(storageServiceProvider).init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PolybiusApp(),
    ),
  );
}
