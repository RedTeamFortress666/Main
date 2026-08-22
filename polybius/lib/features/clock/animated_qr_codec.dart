import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Multi-frame QR stream readable only by a Polybius keyboard scanner.
///
/// Wire format per frame: `PBK1|<index>|<count>|<sid>|<chunk>`
class AnimatedQrCodec {
  AnimatedQrCodec._();

  static const magic = 'PBK1';
  static const chunkChars = 180;

  static String sessionIdForKey(String sessionKey) =>
      sha256.convert(utf8.encode(sessionKey)).toString().substring(0, 8);

  static List<String> split(String sessionKey, String envelope) {
    final sid = sessionIdForKey(sessionKey);
    final chunks = <String>[];
    for (var i = 0; i < envelope.length; i += chunkChars) {
      final end = min(i + chunkChars, envelope.length);
      chunks.add(envelope.substring(i, end));
    }
    if (chunks.isEmpty) chunks.add('');
    final n = chunks.length;
    return [
      for (var i = 0; i < n; i++) '$magic|$i|$n|$sid|${chunks[i]}',
    ];
  }

  static bool isKeyboardFrame(String raw) => parseFrame(raw) != null;

  static _Frame? parseFrame(String raw) {
    final parts = raw.split('|');
    if (parts.length < 5) return null;
    if (parts[0] != magic) return null;
    final index = int.tryParse(parts[1]);
    final count = int.tryParse(parts[2]);
    if (index == null || count == null || count < 1) return null;
    if (index < 0 || index >= count) return null;
    return _Frame(
      index: index,
      count: count,
      sid: parts[3],
      chunk: parts.sublist(4).join('|'),
    );
  }

  /// Joins frames that share [sid]. Returns null until every index is present.
  static String? join(Iterable<String> frames, {String? sid}) {
    final byIndex = <int, _Frame>{};
    var count = 0;
    String? seenSid = sid;
    for (final raw in frames) {
      final f = parseFrame(raw);
      if (f == null) continue;
      if (seenSid != null && f.sid != seenSid) continue;
      seenSid = f.sid;
      count = f.count;
      byIndex[f.index] = f;
    }
    if (count == 0 || byIndex.length != count) return null;
    final buf = StringBuffer();
    for (var i = 0; i < count; i++) {
      final f = byIndex[i];
      if (f == null) return null;
      buf.write(f.chunk);
    }
    return buf.toString();
  }
}

/// Collects PBK1 frames until the envelope can be joined.
class KeyboardQrAssembler {
  KeyboardQrAssembler({this.expectedSid});

  final String? expectedSid;
  final _raw = <String>{};

  int get seen => _raw.length;

  String? add(String raw) {
    if (!AnimatedQrCodec.isKeyboardFrame(raw)) return null;
    _raw.add(raw);
    return AnimatedQrCodec.join(_raw, sid: expectedSid);
  }

  void reset() => _raw.clear();
}

class _Frame {
  const _Frame({
    required this.index,
    required this.count,
    required this.sid,
    required this.chunk,
  });

  final int index;
  final int count;
  final String sid;
  final String chunk;
}

/// Compact screen dump sealed for the keyboard QR stream.
class ScreenDump {
  const ScreenDump({
    required this.text,
    required this.takenAt,
    this.imageSha = '',
  });

  final String text;
  final DateTime takenAt;
  final String imageSha;

  String encode() => jsonEncode({
        'v': 1,
        'app': 'PBK',
        'ts': takenAt.toUtc().toIso8601String(),
        'text': text,
        'sha': imageSha,
      });

  static ScreenDump? tryParse(List<int> bytes) {
    try {
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (map['app'] != 'PBK') return null;
      return ScreenDump(
        text: map['text'] as String? ?? '',
        takenAt: DateTime.parse(map['ts'] as String),
        imageSha: map['sha'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
