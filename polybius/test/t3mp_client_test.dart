import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:polybius/core/net/t3mp_client.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';

void main() {
  group('T3mpClient URL parsing', () {
    test('extracts a drop URL and ignores the upload endpoint', () {
      expect(
        T3mpClient.extractDropUrl('https://temp.sh/dqhSd/cipher.txt'),
        'https://temp.sh/dqhSd/cipher.txt',
      );
      expect(
        T3mpClient.extractDropUrl('drop: https://temp.sh/abc12/pool.sync.'),
        'https://temp.sh/abc12/pool.sync',
      );
      expect(T3mpClient.extractDropUrl('https://temp.sh/upload'), isNull);
      expect(T3mpClient.extractDropUrl('https://github.com/foo/bar'), isNull);
      expect(T3mpClient.isDropUrl('not a url'), isFalse);
    });
  });

  group('T3mpClient HTTP', () {
    test('upload posts multipart and returns the drop URL', () async {
      final client = T3mpClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), T3mpClient.uploadEndpoint);
          expect(request.headers['content-type'], contains('multipart/form-data'));
          return http.Response('https://temp.sh/abc12/cipher.txt\n', 200);
        }),
      );
      final url = await client.uploadText('🔒🔒', filename: 'cipher.txt');
      expect(url, 'https://temp.sh/abc12/cipher.txt');
    });

    test('download POSTs the drop URL (GET is an HTML landing page)', () async {
      final client = T3mpClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), 'https://temp.sh/abc12/cipher.txt');
          return http.Response('emoji-payload', 200);
        }),
      );
      expect(
        await client.downloadText('https://temp.sh/abc12/cipher.txt'),
        'emoji-payload',
      );
    });

    test('upload failure becomes T3mpException', () async {
      final client = T3mpClient(
        httpClient: MockClient((request) async {
          return http.Response('nope', 500);
        }),
      );
      expect(
        () => client.uploadText('x', filename: 'x.txt'),
        throwsA(isA<T3mpException>()),
      );
    });
  });

  group('t3mp + pool sync', () {
    test('a dropped token can be fetched and imported', () async {
      final token = PoolSync.fromSeed('t3mp-seed');
      final wire = token.encode();
      final client = T3mpClient(
        httpClient: MockClient((request) async {
          if (request.url.path == '/upload') {
            return http.Response('https://temp.sh/p00l1/pool.sync', 200);
          }
          expect(request.method, 'POST');
          return http.Response(wire, 200);
        }),
      );

      final url = await client.uploadText(wire, filename: 'pool.sync');
      expect(T3mpClient.isDropUrl(url), isTrue);

      final fetched = await client.downloadText(url);
      final parsed = PoolSync.tryParse(fetched);
      expect(parsed, isNotNull);
      expect(parsed!.seed, 't3mp-seed');
      expect(parsed.verifyIntegrity(), isTrue);
    });
  });

  test('github gist URLs are not treated as t3mp drops', () {
    const gist = 'https://gist.github.com/RedTeamFortress666/deadbeef';
    expect(T3mpClient.isDropUrl(gist), isFalse);
    expect(utf8.encode(gist), isNotEmpty);
  });
}
