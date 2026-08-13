import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gates navigation off `/` until the cinematic boot intro finishes.
final introCompleteProvider = StateProvider<bool>((ref) => false);
