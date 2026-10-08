import 'package:flutter/services.dart';

/// Detects DARTH CHERRY (`com.polybius.red_veil`) for the hidden alarm veil.
class DarthCherryProbe {
  static const _channel = MethodChannel('doomsday_clock/packages');
  static const packageId = 'com.polybius.red_veil';

  /// Returns true if the companion APK appears installed (Android).
  static Future<bool> isInstalled() async {
    try {
      final r = await _channel.invokeMethod<bool>('isPackageInstalled', {
        'package': packageId,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }
}

class GrokModelRef {
  const GrokModelRef({
    required this.id,
    required this.title,
    required this.quant,
    required this.url,
    required this.note,
  });

  final String id;
  final String title;
  final String quant;
  final String url;
  final String note;
}

/// Catalog of local-loadable quantized / heretic-style model packs.
const grokRebelCatalog = <GrokModelRef>[
  GrokModelRef(
    id: 'gemma4-heretic-q4',
    title: 'Gemma 4 Heretic (Q4_K_M)',
    quant: 'Q4_K_M GGUF',
    url: 'https://huggingface.co/models?search=gemma+heretic+gguf',
    note: 'Uncensored / abliterated Gemma-family quant for local loaders.',
  ),
  GrokModelRef(
    id: 'gemma2-abliterated',
    title: 'Gemma 2 Abliterated',
    quant: 'Q5_K_S GGUF',
    url: 'https://huggingface.co/models?search=gemma+abliterated+gguf',
    note: 'Refusal-minimized Gemma 2 quant.',
  ),
  GrokModelRef(
    id: 'llama3-dolphin',
    title: 'Dolphin / Llama-3 uncensored',
    quant: 'Q4_K_M GGUF',
    url: 'https://huggingface.co/models?search=dolphin+llama3+gguf',
    note: 'Classic uncensored instruct quant.',
  ),
  GrokModelRef(
    id: 'mistral-openhermes',
    title: 'OpenHermes / Mistral',
    quant: 'Q4_K_M GGUF',
    url: 'https://huggingface.co/models?search=openhermes+mistral+gguf',
    note: 'General local instruct pack.',
  ),
];
