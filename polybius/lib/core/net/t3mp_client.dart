import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Anonymous 3-day file drops on [temp.sh](https://temp.sh) ("t3mp").
///
/// Shareable Polybius payloads (ciphertext, pool-sync tokens, build zips) go
/// here instead of GitHub Releases / raw GitHub URLs / gists. The host sees
/// only the uploaded bytes; it is not an account-linked pastebin.
///
/// Wire:
/// - mint: `POST multipart file=@bytes` → `https://temp.sh/upload`
/// - fetch: `POST` (empty body) to the drop URL (GET returns an HTML landing
///   page with a download button)
///
/// Flutter **web** cannot talk to temp.sh (no CORS). Native / CLI still work.
class T3mpClient {
  T3mpClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const uploadEndpoint = 'https://temp.sh/upload';
  static const expiry = Duration(days: 3);

  /// `https://temp.sh/<id>/<filename>` — filename may contain dots.
  static final dropUrlPattern = RegExp(
    r'https?://temp\.sh/[A-Za-z0-9_-]+/[A-Za-z0-9._-]+',
    caseSensitive: false,
  );

  final http.Client _http;

  static bool isDropUrl(String raw) => extractDropUrl(raw) != null;

  static String? extractDropUrl(String raw) {
    final match = dropUrlPattern.firstMatch(raw.trim());
    if (match == null) return null;
    var url = match.group(0)!;
    while (url.endsWith('.') || url.endsWith(',') || url.endsWith(')')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.length < 2) return null;
    if (uri.pathSegments.first.toLowerCase() == 'upload') return null;
    return url;
  }

  Future<String> uploadText(String text, {required String filename}) {
    return uploadBytes(utf8.encode(text), filename: filename);
  }

  Future<String> uploadBytes(List<int> bytes, {required String filename}) async {
    if (kIsWeb) throw const T3mpCorsException();
    final safeName = filename.replaceAll(RegExp(r'[/\\]'), '_');
    final request = http.MultipartRequest('POST', Uri.parse(uploadEndpoint));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: safeName),
    );
    final streamed = await _http.send(request);
    final body = (await streamed.stream.bytesToString()).trim();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw T3mpException('t3mp upload failed (${streamed.statusCode})');
    }
    final url = extractDropUrl(body);
    if (url == null) {
      throw T3mpException('t3mp upload returned no drop URL');
    }
    return url;
  }

  Future<Uint8List> download(String urlOrText) async {
    if (kIsWeb) throw const T3mpCorsException();
    final url = extractDropUrl(urlOrText);
    if (url == null) {
      throw T3mpException('not a t3mp URL');
    }
    final response = await _http.post(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw T3mpException('t3mp fetch failed (${response.statusCode})');
    }
    if (response.headers['content-type']?.contains('text/html') == true &&
        utf8.decode(response.bodyBytes, allowMalformed: true).contains('<html')) {
      throw T3mpException('t3mp returned a landing page instead of the file');
    }
    return response.bodyBytes;
  }

  Future<String> downloadText(String urlOrText) async {
    return utf8.decode(await download(urlOrText));
  }
}

class T3mpException implements Exception {
  const T3mpException(this.message);
  final String message;

  @override
  String toString() => message;
}

class T3mpCorsException extends T3mpException {
  const T3mpCorsException()
      : super(
          'Web cannot mint or fetch t3mp drops (temp.sh has no CORS). '
          'Use a native build, or: curl -F file=@payload.txt https://temp.sh/upload',
        );
}
