// Synthesizes an ethereal ambient loop for PØLYBĪUS and writes it to
// assets/audio/polybius_theme.wav.
//
//   dart run tool/gen_music.dart
//
// Pure Dart (no Flutter). Layered sine pad (A-minor-add9) with a slow tremolo
// plus a pentatonic bell arpeggio with decaying echoes for a dreamy tail.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;
const int seconds = 24;

double _sine(double freq, double t) => sin(2 * pi * freq * t);

void main() {
  final n = sampleRate * seconds;
  final buf = Float64List(n);

  // Sustained pad chord (A minor add9-ish).
  const pad = <double>[110.0, 164.81, 220.0, 261.63, 329.63];
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final tremolo = 0.6 + 0.4 * sin(2 * pi * t / 8.0); // 8s LFO
    var s = 0.0;
    for (final f in pad) {
      s += _sine(f, t) + 0.5 * _sine(f * 2.001, t); // slight detune shimmer
    }
    s /= pad.length * 1.5;
    buf[i] += s * 0.32 * tremolo;
  }

  // Pentatonic bell arpeggio (eighth notes at 80 BPM) with echo tail.
  const arp = <double>[220.0, 261.63, 329.63, 392.0, 329.63, 261.63, 293.66, 220.0];
  const step = 60.0 / 80.0 / 2.0; // 0.375s
  const decay = 0.45;
  final tail = (decay * 3 * sampleRate).floor();
  for (var k = 0; k * step < seconds; k++) {
    final f = arp[k % arp.length];
    final start = k * step;
    for (var echo = 0; echo < 4; echo++) {
      final es = start + echo * step * 1.5;
      final gain = 0.5 * pow(0.55, echo).toDouble();
      final startIdx = (es * sampleRate).floor();
      for (var j = 0; j < tail; j++) {
        final idx = startIdx + j;
        if (idx >= n) break;
        final tt = j / sampleRate;
        final env = exp(-tt / decay);
        buf[idx] += gain * env * (_sine(f, tt) + 0.4 * _sine(f * 2, tt));
      }
    }
  }

  // Normalize to -1.4 dBFS.
  var peak = 0.0;
  for (final v in buf) {
    peak = max(peak, v.abs());
  }
  final scale = peak > 0 ? 0.85 / peak : 1.0;

  final dataLen = n * 2;
  final out = BytesBuilder();
  final header = ByteData(44);
  void tag(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  header.setUint32(4, 36 + dataLen, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  header.setUint32(40, dataLen, Endian.little);
  out.add(header.buffer.asUint8List());

  final pcm = ByteData(dataLen);
  for (var i = 0; i < n; i++) {
    final v = (buf[i] * scale * 32767).round().clamp(-32768, 32767);
    pcm.setInt16(i * 2, v, Endian.little);
  }
  out.add(pcm.buffer.asUint8List());

  final file = File('assets/audio/polybius_theme.wav');
  file.createSync(recursive: true);
  file.writeAsBytesSync(out.toBytes());
  // ignore: avoid_print
  print('wrote ${file.path} (${(dataLen / 1e6).toStringAsFixed(2)} MB)');
}
