// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:polybius/features/roundtable/traffic_sketch.dart';
import 'package:polybius/features/stego/stego_vet.dart';

/// Tailscale / Proxmox stego-vet daemon.
///
/// Bind to a tailnet address on a Proxmox LXC:
///
///   dart run tool/stego_vet_sidecar.dart --host 100.x.y.z --port 3743
///
/// The MAC key is created on first run under `--state` and never sent
/// to cabinets. Analyst notes stay in this process. Cabinets only get
/// a receipt + a boiled pattern report.
///
/// Default bind is loopback so a laptop can run the same daemon next
/// to the RNS sidecar (3742).
Future<void> main(List<String> args) async {
  var host = '127.0.0.1';
  var port = 3743;
  var stateDir = '${Directory.current.path}/.vet_sidecar';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--host' && i + 1 < args.length) host = args[++i];
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.parse(args[++i]);
    }
    if (args[i] == '--state' && i + 1 < args.length) stateDir = args[++i];
  }

  final dir = Directory(stateDir)..createSync(recursive: true);
  final keyFile = File('${dir.path}/mac.key');
  Uint8List key;
  if (keyFile.existsSync()) {
    key = Uint8List.fromList(base64Decode(keyFile.readAsStringSync().trim()));
  } else {
    final rng = Random.secure();
    key = Uint8List.fromList(List<int>.generate(32, (_) => rng.nextInt(256)));
    keyFile.writeAsStringSync(base64Encode(key));
    keyFile.setPermissionsIfPossible();
  }

  final authority = StegoVetAuthority(key, origin: 'sidecar');
  final server = await ServerSocket.bind(host, port);
  stderr.writeln('STEGO VET SIDECAR $host:$port  (notes stay here)');

  await for (final socket in server) {
    socket.listen((data) async {
      for (final line in utf8.decode(data).split('\n')) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line);
          if (map is! Map) continue;
          final op = map['op'];
          if (op == 'hello') {
            socket.write('${jsonEncode({
                  'op': 'hello',
                  'origin': 'sidecar',
                  'seats': 5,
                })}\n');
            continue;
          }
          if (op != 'vet') continue;
          final fp = StegoFingerprint(
            digestHex: map['fp'] as String? ?? '',
            decoyCount: (map['decoys'] as num?)?.toInt() ?? 0,
          );
          TrafficSketch? sketch;
          final raw = map['sketch'];
          if (raw is Map) {
            sketch = TrafficSketch.fromJson(Map<String, dynamic>.from(raw));
          }
          final out = authority.vet(fingerprint: fp, sketch: sketch);
          socket.write('${jsonEncode({
                'op': 'receipt',
                'receipt': out.receipt.toJson(),
                'report': out.report.toJson(),
              })}\n');
        } catch (e) {
          socket.write('${jsonEncode({'op': 'error', 'e': '$e'})}\n');
        }
      }
      await socket.flush();
    });
  }
}

extension on File {
  void setPermissionsIfPossible() {
    try {
      Process.runSync('chmod', ['600', path]);
    } catch (_) {}
  }
}
