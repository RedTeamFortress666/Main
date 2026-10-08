import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:polybius/core/storage/polybius_secret_store.dart';

class _FlutterSecurePolybiusSecretStore implements PolybiusSecretStore {
  _FlutterSecurePolybiusSecretStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

PolybiusSecretStore createPolybiusSecretStore() {
  return _FlutterSecurePolybiusSecretStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      webOptions: WebOptions(
        dbName: 'polybius',
        publicKey: 'polybius_web_storage',
      ),
    ),
  );
}
