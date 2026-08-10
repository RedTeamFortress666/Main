import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Detects DARTH CHERRY companion package + live filter beacon for the
/// hidden alarm veil (same beacon Polybius uses: `127.0.0.1:18766`).
class DarthCherryProbe {
  static const _channel = MethodChannel('doomsday_clock/packages');
  static const packageId = 'com.polybius.red_veil';
  static const beaconPort = 18766;

  /// True if the companion APK appears installed (Android package query).
  static Future<bool> isInstalled() async {
    if (kIsWeb) return false;
    try {
      final r = await _channel.invokeMethod<bool>('isPackageInstalled', {
        'package': packageId,
      });
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// True when DARTH CHERRY filter overlay is actively serving its beacon.
  /// This is what makes the eye visible (same contract as Polybius cipher).
  static Future<FilterBeaconStatus> probeFilter() async {
    if (kIsWeb) {
      return const FilterBeaconStatus(active: false, intensity: 0);
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 400);
    try {
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:$beaconPort/veil'),
      );
      req.headers.set(HttpHeaders.connectionHeader, 'close');
      final res =
          await req.close().timeout(const Duration(milliseconds: 500));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        return const FilterBeaconStatus(active: false, intensity: 0);
      }
      final json = jsonDecode(body);
      if (json is Map && json['active'] == true) {
        final intensity = (json['intensity'] as num?)?.toDouble() ?? 0.55;
        return FilterBeaconStatus(active: true, intensity: intensity);
      }
      return const FilterBeaconStatus(active: false, intensity: 0);
    } catch (_) {
      return const FilterBeaconStatus(active: false, intensity: 0);
    } finally {
      client.close(force: true);
    }
  }
}

class FilterBeaconStatus {
  const FilterBeaconStatus({required this.active, required this.intensity});
  final bool active;
  final double intensity;
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
