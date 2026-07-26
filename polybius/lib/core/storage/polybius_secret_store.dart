/// Platform-backed secret persistence for encryption keys.
abstract interface class PolybiusSecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}
