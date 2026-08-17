import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/shadow_theme.dart';
import '../../providers/mesh_providers.dart';
import '../widgets/model_tile.dart';

class ModelVaultScreen extends ConsumerWidget {
  const ModelVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesh = ref.watch(meshControllerProvider);
    final controller = ref.read(meshControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('MODEL VAULT', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Abliterated uncensored GGUF weights · 2–6 GB phone band',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickGgufFile(context, controller, mesh),
                icon: const Icon(Icons.file_open),
                label: const Text('BIND GGUF FILE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ShadowTheme.neonPurple,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _scanDirectory(context, controller),
                icon: const Icon(Icons.folder_open),
                label: const Text('SCAN FOLDER'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('CATALOG', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ...mesh.models.map(
          (m) => ModelTile(
            model: m,
            onBind: () => _pickGgufForModel(context, controller, m.id),
          ),
        ),
      ],
    );
  }

  Future<void> _pickGgufFile(
    BuildContext context,
    MeshController controller,
    MeshState mesh,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final bytes = File(path).lengthSync();
    final gb = bytes / (1024 * 1024 * 1024);

    final match = mesh.models.firstWhere(
      (m) => m.inTargetRange && (m.sizeGb - gb).abs() < 1.5,
      orElse: () => mesh.models.first,
    );
    await controller.bindModel(match.id, path, bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bound to ${match.displayName}')),
      );
    }
  }

  Future<void> _pickGgufForModel(
    BuildContext context,
    MeshController controller,
    String modelId,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final bytes = File(path).lengthSync();
    await controller.bindModel(modelId, path, bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model path updated')),
      );
    }
  }

  Future<void> _scanDirectory(
    BuildContext context,
    MeshController controller,
  ) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await controller.scanModelsDir(path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned $path')),
      );
    }
  }
}
