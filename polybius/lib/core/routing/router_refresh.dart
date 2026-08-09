import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polybius/core/providers/app_providers.dart';
import 'package:polybius/core/providers/intro_provider.dart';

/// Notifies [GoRouter] when auth/unlock/intro changes without recreating the router.
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(unlockProvider, (_, _) => notifyListeners());
    ref.listen(introCompleteProvider, (_, _) => notifyListeners());
  }
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return refresh;
});
