import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/constants/operator_identities.dart';
import 'package:polybius/core/crypto/encryption_service.dart';
import 'package:polybius/core/providers/app_providers.dart';

/// Session gate for viewing the raw 560-emoji daily pool (leak prevention).
/// Encrypt / decrypt / QR sync remain available without unlocking the grid.
class PoolViewGateState {
  const PoolViewGateState({
    this.unlocked = false,
    this.error,
  });

  final bool unlocked;
  final String? error;

  PoolViewGateState copyWith({bool? unlocked, String? error, bool clearError = false}) =>
      PoolViewGateState(
        unlocked: unlocked ?? this.unlocked,
        error: clearError ? null : (error ?? this.error),
      );
}

class PoolViewGateNotifier extends StateNotifier<PoolViewGateState> {
  PoolViewGateNotifier(this._ref) : super(const PoolViewGateState());

  final Ref _ref;

  void lock() => state = const PoolViewGateState();

  /// Requires the bound / operator game-file number plus the account's 6-digit PIN.
  Future<bool> unlock({
    required String gameFileNumber,
    required String pin,
  }) async {
    final auth = _ref.read(authProvider);
    final user = auth.user;
    if (user == null) {
      state = const PoolViewGateState(error: 'LOGIN REQUIRED');
      return false;
    }

    final file = gameFileNumber.trim().toUpperCase();
    final pinDigits = pin.trim();
    if (file.isEmpty) {
      state = const PoolViewGateState(error: 'ENTER GAME FILE NUMBER');
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pinDigits)) {
      state = const PoolViewGateState(error: 'PIN MUST BE 6 DIGITS');
      return false;
    }

    final storage = _ref.read(storageServiceProvider);
    final bound = (await storage.getGameFileNumber())?.trim().toUpperCase();
    final identity = OperatorIdentities.byUsername(user.username);
    final accepted = <String>{
      if (bound != null && bound.isNotEmpty) bound,
      if (identity != null) identity.inviteOrFileCode.trim().toUpperCase(),
    };

    if (accepted.isEmpty || !accepted.contains(file)) {
      await storage.logAudit('POOL_VIEW_DENY_FILE', user.username, file);
      state = const PoolViewGateState(error: 'GAME FILE NUMBER REJECTED');
      return false;
    }

    if (!EncryptionService.verifyPin(pinDigits, user.pinHash)) {
      await storage.logAudit('POOL_VIEW_DENY_PIN', user.username);
      state = const PoolViewGateState(error: 'INVALID PIN');
      return false;
    }

    await storage.logAudit('POOL_VIEW_UNLOCK', user.username);
    state = const PoolViewGateState(unlocked: true);
    return true;
  }
}

final poolViewGateProvider =
    StateNotifierProvider<PoolViewGateNotifier, PoolViewGateState>((ref) {
  final notifier = PoolViewGateNotifier(ref);
  ref.listen(authProvider, (prev, next) {
    if (prev?.user?.username != next.user?.username) {
      notifier.lock();
    }
  });
  return notifier;
});
