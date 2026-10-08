import 'dart:math';

/// Multi-frame QR stream. Each envelope gets a fresh [sid] so two QRs are
/// never identical, even for the same public key or message class.
///
/// Wire format: `DC3|<sid>|<index>|<count>|<chunk>`
class UniqueQrCodec {
  UniqueQrCodec._();

  static const magic = 'DC3';
  static const chunkChars = 160;

  static List<String> split(String payload, {String? sid}) {
    final id = sid ?? _freshSid();
    final chunks = <String>[];
    for (var i = 0; i < payload.length; i += chunkChars) {
      final end = min(i + chunkChars, payload.length);
      chunks.add(payload.substring(i, end));
    }
    if (chunks.isEmpty) chunks.add('');
    final n = chunks.length;
    return [
      for (var i = 0; i < n; i++) '$magic|$id|$i|$n|${chunks[i]}',
    ];
  }

  static String _freshSid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(10, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static bool isFrame(String raw) => _parse(raw) != null;

  static _Frame? _parse(String raw) {
    final parts = raw.split('|');
    if (parts.length < 5) return null;
    if (parts[0] != magic) return null;
    final index = int.tryParse(parts[2]);
    final count = int.tryParse(parts[3]);
    if (index == null || count == null || count < 1) return null;
    if (index < 0 || index >= count) return null;
    return _Frame(
      sid: parts[1],
      index: index,
      count: count,
      chunk: parts.sublist(4).join('|'),
    );
  }

  static String? join(Iterable<String> frames, {String? sid}) {
    final byIndex = <int, _Frame>{};
    var count = 0;
    String? seen = sid;
    for (final raw in frames) {
      final f = _parse(raw);
      if (f == null) continue;
      if (seen != null && f.sid != seen) continue;
      seen = f.sid;
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

class UniqueQrAssembler {
  UniqueQrAssembler({this.expectedSid});

  final String? expectedSid;
  final _raw = <String>{};

  int get seen => _raw.length;

  String? add(String raw) {
    if (!UniqueQrCodec.isFrame(raw)) return null;
    _raw.add(raw);
    return UniqueQrCodec.join(_raw, sid: expectedSid);
  }

  void reset() => _raw.clear();
}

class _Frame {
  const _Frame({
    required this.sid,
    required this.index,
    required this.count,
    required this.chunk,
  });

  final String sid;
  final int index;
  final int count;
  final String chunk;
}
