import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/core/constants/app_constants.dart';
import 'package:polybius/core/constants/master_glyphs.dart';
import 'package:polybius/features/cipher/engine/pool_manager.dart';

void main() {
  test('master cabinet is unique and larger than the active window', () {
    expect(MasterGlyphs.size, greaterThan(AppConstants.poolSize));
    expect(MasterGlyphs.all.toSet().length, MasterGlyphs.size);
  });

  test('daily draw is 560 unique glyphs', () {
    final mgr = PoolManager(
      seed: 'alpha',
      at: DateTime.utc(2026, 8, 29, 0),
    );
    expect(mgr.dailyDraw.length, AppConstants.poolSize);
    expect(mgr.dailyDraw.toSet().length, AppConstants.poolSize);
  });

  test('2-hour slots remap the same daily draw', () {
    final day = DateTime.utc(2026, 8, 29, 1);
    final later = DateTime.utc(2026, 8, 29, 3);
    final a = PoolManager(seed: 'alpha', at: day);
    final b = PoolManager(seed: 'alpha', at: later);
    expect(a.dailyDraw, equals(b.dailyDraw));
    expect(a.activePool, isNot(equals(b.activePool)));
    expect(a.slot, 0);
    expect(b.slot, 1);
  });

  test('same slot is stable', () {
    final a = PoolManager(seed: 'alpha', at: DateTime.utc(2026, 8, 29, 4));
    final b = PoolManager(seed: 'alpha', at: DateTime.utc(2026, 8, 29, 5));
    expect(a.slot, b.slot);
    expect(a.activePool, equals(b.activePool));
  });
}
