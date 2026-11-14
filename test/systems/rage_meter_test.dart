import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/systems/rage_meter.dart';

void main() {
  group('RageMeter', () {
    test('fills to full after the configured number of escapes', () {
      final rage = RageMeter(fillPerEscape: 0.2);
      for (var i = 0; i < 4; i++) {
        rage.onCarEscaped();
      }
      expect(rage.isFull, isFalse);
      rage.onCarEscaped();
      expect(rage.isFull, isTrue);
      expect(rage.value, 1);
    });

    test('splats drain rage but never below zero', () {
      final rage = RageMeter(fillPerEscape: 0.2, drainPerSplat: 0.1)
        ..onCarEscaped()
        ..onCarSplatted();
      expect(rage.value, closeTo(0.1, 1e-9));
      rage
        ..onCarSplatted()
        ..onCarSplatted();
      expect(rage.value, 0);
    });

    test('is full despite floating point drift', () {
      final rage = RageMeter(fillPerEscape: 0.1);
      for (var i = 0; i < 10; i++) {
        rage.onCarEscaped();
      }
      expect(rage.isFull, isTrue);
    });
  });
}
