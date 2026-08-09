import 'package:flutter_test/flutter_test.dart';
import 'package:polybius/features/cipher/veil/veil_state.dart';

void main() {
  group('VeilNotifier', () {
    test('starts normal with filter inactive', () {
      final n = VeilNotifier();
      expect(n.state.filterActive, isFalse);
      expect(n.state.mode, VeilMode.normal);
      expect(n.state.eyeVisible, isFalse);
      n.dispose();
    });

    test('echo/matrix require an active filter', () {
      final n = VeilNotifier();
      n.toggleEcho();
      expect(n.state.mode, VeilMode.normal);
      n.engageMatrix();
      expect(n.state.mode, VeilMode.normal);
      n.dispose();
    });

    test('toggleEcho and engageMatrix work when filter is active', () {
      final n = VeilNotifier();
      n.debugSetFilterActive(true);
      expect(n.state.eyeVisible, isTrue);

      n.toggleEcho();
      expect(n.state.mode, VeilMode.echo);
      n.toggleEcho();
      expect(n.state.mode, VeilMode.normal);

      n.engageMatrix();
      expect(n.state.mode, VeilMode.matrix);
      n.toggleEcho();
      expect(n.state.mode, VeilMode.normal);
      n.dispose();
    });

    test('losing the filter resets mode to normal', () {
      final n = VeilNotifier();
      n.debugSetFilterActive(true);
      n.engageMatrix();
      expect(n.state.mode, VeilMode.matrix);
      n.debugSetFilterActive(false);
      expect(n.state.mode, VeilMode.normal);
      expect(n.state.filterActive, isFalse);
      n.dispose();
    });
  });
}
