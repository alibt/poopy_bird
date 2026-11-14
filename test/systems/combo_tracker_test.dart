import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/systems/combo_tracker.dart';

void main() {
  group('ComboTracker', () {
    test('multiplier grows with consecutive hits up to the cap', () {
      final combo = ComboTracker(window: 2, maxMultiplier: 3);
      expect(combo.multiplier, 1);
      expect(
          [for (var i = 0; i < 5; i++) combo.registerHit()], [1, 2, 3, 3, 3]);
      expect(combo.best, 5);
    });

    test('expires after the window with no hits', () {
      final combo = ComboTracker(window: 2)
        ..registerHit()
        ..registerHit();
      combo.update(1.9);
      expect(combo.count, 2);
      combo.update(0.2);
      expect(combo.count, 0);
      expect(combo.multiplier, 1);
    });

    test('each hit refreshes the window', () {
      final combo = ComboTracker(window: 2)..registerHit();
      combo.update(1.5);
      combo.registerHit();
      combo.update(1.5);
      expect(combo.count, 2);
    });

    test('a miss breaks the combo but keeps the best', () {
      final combo = ComboTracker()
        ..registerHit()
        ..registerHit()
        ..registerMiss();
      expect(combo.count, 0);
      expect(combo.best, 2);
    });
  });
}
