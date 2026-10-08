import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/storage/storage_service.dart';
import 'package:polybius/features/clock/alphabet_pool.dart';
import 'package:polybius/features/clock/clock_ritual.dart';
import 'package:polybius/features/clock/session_binary_key.dart';

class ClockSession {
  const ClockSession({
    this.unlocked = false,
    this.mustChangePassword = true,
    this.cherryActive = false,
    this.hour = 0,
    this.minute = 0,
    this.alarm = '',
    this.showFalseAlarm = false,
    this.alphabetSeed,
    this.sessionKey,
  });

  final bool unlocked;
  final bool mustChangePassword;
  final bool cherryActive;
  final int hour;
  final int minute;
  final String alarm;
  final bool showFalseAlarm;
  final String? alphabetSeed;
  final String? sessionKey;

  ClockSession copyWith({
    bool? unlocked,
    bool? mustChangePassword,
    bool? cherryActive,
    int? hour,
    int? minute,
    String? alarm,
    bool? showFalseAlarm,
    String? alphabetSeed,
    String? sessionKey,
    bool clearSessionKey = false,
  }) =>
      ClockSession(
        unlocked: unlocked ?? this.unlocked,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
        cherryActive: cherryActive ?? this.cherryActive,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        alarm: alarm ?? this.alarm,
        showFalseAlarm: showFalseAlarm ?? this.showFalseAlarm,
        alphabetSeed: alphabetSeed ?? this.alphabetSeed,
        sessionKey: clearSessionKey ? null : (sessionKey ?? this.sessionKey),
      );
}

class ClockSessionNotifier extends StateNotifier<ClockSession> {
  ClockSessionNotifier(this._storage) : super(_nowFace()) {
    _load();
  }

  final StorageService _storage;

  static ClockSession _nowFace() {
    final n = DateTime.now();
    return ClockSession(hour: n.hour, minute: n.minute);
  }

  Future<void> _load() async {
    await _storage.ensureClockFactoryPassword();
    final changed = await _storage.getClockPasswordChanged();
    final seed = await _storage.getClockAlphabetSeed();
    state = state.copyWith(
      mustChangePassword: !changed,
      alphabetSeed: seed,
    );
  }

  Future<String?> unlock(String password) async {
    await _storage.ensureClockFactoryPassword();
    final hash = await _storage.getClockPasswordHash();
    if (hash == null || !EncryptionService.verifyPassword(password, hash)) {
      return 'ACCESS DENIED';
    }
    if (EncryptionService.isLegacyHash(hash)) {
      await _storage.setClockPasswordHash(
        EncryptionService.hashPassword(password),
      );
    }
    final changed = await _storage.getClockPasswordChanged();
    state = state.copyWith(unlocked: true, mustChangePassword: !changed);
    return null;
  }

  Future<String?> changePassword(String next) async {
    final trimmed = next.trim();
    if (trimmed.length < 4) return 'TOO SHORT';
    if (trimmed == ClockRitual.factoryPassword) {
      return 'CHOOSE A NEW CODE';
    }
    await _storage.setClockPasswordHash(EncryptionService.hashPassword(trimmed));
    await _storage.setClockPasswordChanged(true);
    state = state.copyWith(mustChangePassword: false, unlocked: true);
    return null;
  }

  void setFace({int? hour, int? minute}) {
    state = state.copyWith(
      hour: hour != null ? hour % 24 : null,
      minute: minute != null ? minute % 60 : null,
    );
  }

  void setAlarm(String value) => state = state.copyWith(alarm: value);

  void setCherryActive(bool value) =>
      state = state.copyWith(cherryActive: value);

  bool get deskReady => ClockRitual.canOpenDesk(
        hour: state.hour,
        minute: state.minute,
        alarm: state.alarm,
        cherryActive: state.cherryActive,
      );

  void lock() {
    state = ClockSession(
      hour: state.hour,
      minute: state.minute,
      mustChangePassword: state.mustChangePassword,
      alphabetSeed: state.alphabetSeed,
    );
  }

  void raiseFalseAlarm() => state = state.copyWith(showFalseAlarm: true);

  void dismissFalseAlarm() => state = state.copyWith(showFalseAlarm: false);

  Future<void> setAlphabetSeed(String seed) async {
    await _storage.setClockAlphabetSeed(seed);
    state = state.copyWith(alphabetSeed: seed);
  }

  void setSessionKey(String key) {
    final trimmed = key.trim();
    if (!SessionBinaryKey.isValid(trimmed)) return;
    state = state.copyWith(sessionKey: trimmed);
  }

  void clearSessionKey() => state = state.copyWith(clearSessionKey: true);

  Future<AlphabetPool> randomisePool() async {
    final pool = AlphabetPool.randomise();
    await setAlphabetSeed(pool.seed);
    return pool;
  }

  AlphabetPool get pool => AlphabetPool(
        seed: state.alphabetSeed ?? 'clock-factory',
      );
}

final clockSessionProvider =
    StateNotifierProvider<ClockSessionNotifier, ClockSession>((ref) {
  return ClockSessionNotifier(ref.read(storageServiceProvider));
});
