import 'dart:html' as html;

import 'package:polybius/core/storage/polybius_secret_store.dart';

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
