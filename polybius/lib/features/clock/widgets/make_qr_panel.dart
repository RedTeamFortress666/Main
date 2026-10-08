import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polybius/features/clock/session_binary_key.dart';

/// MAKE QR? session-key entry: paste an existing key or create one and cut it.
class MakeQrPanel extends StatelessWidget {
  const MakeQrPanel({
    super.key,
    required this.enterController,
    required this.createdController,
    required this.onEnter,
    required this.onCreated,
  });

  final TextEditingController enterController;
  final TextEditingController createdController;
  final ValueChanged<String> onEnter;
  final ValueChanged<String> onCreated;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    enterController.text = text;
    onEnter(text);
  }

  void _create() {
    final key = SessionBinaryKey.create();
    createdController.text = key;
    onCreated(key);
  }

  Future<void> _cut() async {
    final text = createdController.text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    createdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    const cherry = Color(0xFFFF2A4D);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'MAKE QR?',
          style: TextStyle(
            fontFamily: 'monospace',
            color: cherry,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'enter session binary auth key?',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFFFC1C8),
            fontSize: 12,
          ),
        ),
        TextField(
          key: const Key('session-key-enter'),
          controller: enterController,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'PBK-…',
            hintStyle: TextStyle(color: Colors.white24),
          ),
          onChanged: onEnter,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('session-key-paste'),
            onPressed: _paste,
            child: const Text('PASTE'),
          ),
        ),
        const Text(
          'create session binary key?',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFFFFC1C8),
            fontSize: 12,
          ),
        ),
        TextField(
          key: const Key('session-key-created'),
          controller: createdController,
          readOnly: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'tap CREATE',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              key: const Key('session-key-create'),
              onPressed: _create,
              child: const Text('CREATE'),
            ),
            TextButton(
              key: const Key('session-key-cut'),
              onPressed: _cut,
              child: const Text('CUT'),
            ),
          ],
        ),
      ],
    );
  }
}
