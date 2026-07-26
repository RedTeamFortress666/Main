import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';

/// Notifies [GoRouter] when auth/unlock changes without recreating the router.
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(unlockProvider, (_, __) => notifyListeners());
  }
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});
