import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A COPY / PASTE button row placed under a text box. COPY copies the box's
/// text; PASTE writes the clipboard contents into the box's input controller.
class ClipboardRow extends StatelessWidget {
  const ClipboardRow({
    super.key,
    required this.color,
    required this.getCopyText,
    required this.onPaste,
  });

  final Color color;
  final String Function() getCopyText;
  final ValueChanged<String> onPaste;

  Future<void> _copy(BuildContext context) async {
    final text = getCopyText();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _paste(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) onPaste(text);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => _copy(context),
          icon: Icon(Icons.copy, color: color, size: 18),
          label: Text('COPY', style: TextStyle(color: color)),
        ),
        TextButton.icon(
          onPressed: () => _paste(context),
          icon: Icon(Icons.content_paste, color: color, size: 18),
          label: Text('PASTE', style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
