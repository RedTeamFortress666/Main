import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loops the ethereal PØLYBĪUS theme, gated by the sound setting.
///
/// All calls are guarded: on platforms without an audio backend (or before the
/// first user gesture on web) failures are swallowed so the app keeps running.
class MusicService {
  // Created lazily so merely constructing the service (e.g. in a test) does not
  // touch the audio plugin, which has no implementation in headless tests.
  AudioPlayer? _player;
  bool _loaded = false;

  Future<void> setEnabled(bool enabled) async {
    try {
      final player = _player ??= AudioPlayer();
      if (!enabled) {
        await player.pause();
        return;
      }
      if (!_loaded) {
        _loaded = true;
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(0.45);
        await player.play(AssetSource('audio/polybius_theme.wav'));
      } else {
        await player.resume();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Music playback unavailable: $error');
      }
    }
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}

final musicServiceProvider = Provider<MusicService>((ref) {
  final service = MusicService();
  ref.onDispose(service.dispose);
  return service;
});
