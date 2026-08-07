import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Matches [kVeilBeaconPort] in the red_veil companion app.
const int kRedVeilBeaconPort = 18766;

/// Stealth typing modes revealed only while RED VEIL is overlaid.
enum VeilMode {
  /// Normal visible plaintext (default).
  normal,

  /// Each typed letter flashes then fades.
  echo,

  /// Plaintext is not shown; cipher shell takes a matrix green tint.
  matrix,
}

class VeilState {
  const VeilState({
    this.filterActive = false,
    this.mode = VeilMode.normal,
    this.intensity = 0.0,
  });

  final bool filterActive;
  final VeilMode mode;
  final double intensity;

  /// Eyeball is shown only when the red filter beacon is alive.
  bool get eyeVisible => filterActive;

  VeilState copyWith({
    bool? filterActive,
    VeilMode? mode,
    double? intensity,
  }) =>
      VeilState(
        filterActive: filterActive ?? this.filterActive,
        mode: mode ?? this.mode,
        intensity: intensity ?? this.intensity,
      );
}

class VeilNotifier extends StateNotifier<VeilState> {
  VeilNotifier() : super(const VeilState());

  Timer? _poll;
  HttpClient? _client;

  /// Start polling the RED VEIL beacon. Call when the cipher shell opens.
  void startWatching() {
    if (kIsWeb) return;
    _poll?.cancel();
    _client ??= HttpClient()..connectionTimeout = const Duration(milliseconds: 400);
    _poll = Timer.periodic(const Duration(milliseconds: 900), (_) => _tick());
    _tick();
  }

  void stopWatching() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _tick() async {
    if (kIsWeb) return;
    final client = _client;
    if (client == null) return;
    try {
      final req = await client.getUrl(
        Uri.parse('http://127.0.0.1:$kRedVeilBeaconPort/veil'),
      );
      req.headers.set(HttpHeaders.connectionHeader, 'close');
      final res = await req.close().timeout(const Duration(milliseconds: 500));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        _setFilter(false);
        return;
      }
      final json = jsonDecode(body);
      if (json is Map && json['active'] == true) {
        final intensity = (json['intensity'] as num?)?.toDouble() ?? 0.55;
        if (!state.filterActive || state.intensity != intensity) {
          state = state.copyWith(filterActive: true, intensity: intensity);
        }
      } else {
        _setFilter(false);
      }
    } catch (_) {
      _setFilter(false);
    }
  }

  void _setFilter(bool active) {
    if (!active && state.filterActive) {
      // Closing the dimmer drops matrix/echo — plaintext returns to normal.
      state = const VeilState();
    } else if (active != state.filterActive) {
      state = state.copyWith(filterActive: active);
    }
  }

  void setMode(VeilMode mode) {
    if (!state.filterActive && mode != VeilMode.normal) return;
    state = state.copyWith(mode: mode);
  }

  void toggleEcho() {
    if (!state.filterActive) return;
    if (state.mode == VeilMode.matrix) {
      state = state.copyWith(mode: VeilMode.normal);
      return;
    }
    state = state.copyWith(
      mode: state.mode == VeilMode.echo ? VeilMode.normal : VeilMode.echo,
    );
  }

  void engageMatrix() {
    if (!state.filterActive) return;
    state = state.copyWith(mode: VeilMode.matrix);
  }

  /// Test / debug: force filter presence without the beacon.
  @visibleForTesting
  void debugSetFilterActive(bool active, {double intensity = 0.55}) {
    if (!active) {
      state = const VeilState();
    } else {
      state = state.copyWith(filterActive: true, intensity: intensity);
    }
  }

  @override
  void dispose() {
    stopWatching();
    _client?.close(force: true);
    super.dispose();
  }
}

final veilProvider = StateNotifierProvider<VeilNotifier, VeilState>((ref) {
  final n = VeilNotifier();
  ref.onDispose(n.dispose);
  return n;
});
