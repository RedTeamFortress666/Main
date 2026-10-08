import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:polybius/features/cipher/engine/cipher_engine.dart';
import 'package:polybius/features/cipher/engine/daily_pool.dart';
import 'package:polybius/features/cipher/engine/pool_sync.dart';
import 'package:polybius/features/cipher/engine/rotor.dart';

void main() {
  final seed = '2026-07-22';
  final pool = DailyPool(seed: seed).generate();
  print('POOL_LEN ${pool.length}');
  print('POOL0 ${pool[0]}');
  print('POOL1 ${pool[1]}');
  print('POOL279 ${pool[279]}');
  print('POOL280 ${pool[280]}');
  print('POOL559 ${pool[559]}');
  print('POOL_ID ${PoolSync.poolIdFor(seed)}');
  print('POOL_HASH ${sha256.convert(utf8.encode(pool.join())).toString().substring(0, 16)}');
  print('HASHCODE ${seed.hashCode}');
  final r = Rotor.create('I', seed, 0);
  print('ROTOR_I_NOTCH ${r.notch}');
  print('ROTOR_I_W0 ${r.wiring[0]}');
  print('ROTOR_I_W1 ${r.wiring[1]}');
  print('ROTOR_I_W100 ${r.wiring[100]}');
  final e = CipherEngine(seed: seed, complexity: 2);
  final enc = e.encrypt('HELLO');
  print('ENC_HELLO_CPS ${enc.runes.toList()}');
  print('DEC ${CipherEngine(seed: seed).decrypt(enc)}');
  final e3 = CipherEngine(seed: 'complexity-seed', complexity: 3);
  final enc3 = e3.encrypt('AB');
  print('ENC_AB_C3_CPS ${enc3.runes.toList()}');
  print('POOL_HEAD_CPS ${pool.take(20).map((e) => e.runes.first).toList()}');
  // Dart Random probe
  final rng = Random(42);
  print('DART_RND42 ${List.generate(10, (_) => rng.nextInt(280))}');
}
