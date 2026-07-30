import 'dart:html' as html;

import 'package:polybius/core/storage/polybius_secret_store.dart';

/// SECURITY: on web the AES key lives in localStorage in plaintext, so local
/// data is only obfuscated, not protected from an attacker with browser
/// access. Acceptable for beta previews; native builds use platform secure
/// storage via flutter_secure_storage instead.
class _WebPolybiusSecretStore implements PolybiusSecretStore {
  static const _prefix = 'polybius.secret.';

  @override
  Future<String?> read(String key) async =>
      html.window.localStorage['$_prefix$key'];

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage['$_prefix$key'] = value;
  }
}

PolybiusSecretStore createPolybiusSecretStore() => _WebPolybiusSecretStore();
