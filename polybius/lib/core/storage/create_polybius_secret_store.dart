import 'package:polybius/core/storage/polybius_secret_store.dart';
import 'polybius_secret_store_io.dart'
    if (dart.library.html) 'polybius_secret_store_web.dart' as platform;

PolybiusSecretStore createPolybiusSecretStore() =>
    platform.createPolybiusSecretStore();
