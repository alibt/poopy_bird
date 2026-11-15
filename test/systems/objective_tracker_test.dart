import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/levels/level_definition.dart';
import 'package:poopy_bird/systems/car_type.dart';
import 'package:poopy_bird/systems/objective_tracker.dart';

void main() {
  group('ObjectiveTracker', () {
    test('counts splats, optionally of one car type', () {
      final tracker = ObjectiveTracker(const [
        ObjectiveDefinition(type: ObjectiveType.splatCars, count: 2),
        ObjectiveDefinition(
            type: ObjectiveType.splatCars,
            count: 1,
            carType: CarType.sportsCar),
      ]);
      tracker.onSplat(CarType.sedan);
      expect(tracker.isMet(0), isFalse);
      expect(tracker.isMet(1), isFalse);
      tracker.onSplat(CarType.sportsCar);
      expect(tracker.allMet, isTrue);
      expect(tracker.progressLabel(0), '2/2');
    });

    test('combo and score keep the highest value reached', () {
      final tracker = ObjectiveTracker(const [
        ObjectiveDefinition(type: ObjectiveType.reachCombo, count: 3),
        ObjectiveDefinition(type: ObjectiveType.reachScore, count: 1000),
      ]);
      tracker
        ..onCombo(3)
        ..onCombo(1)
        ..onScore(1200)
        ..onScore(10);
      expect(tracker.allMet, isTrue);
    });

    test('max escapes is met until exceeded, then failed', () {
      final tracker = ObjectiveTracker(const [
        ObjectiveDefinition(type: ObjectiveType.maxEscapes, count: 1),
      ]);
      expect(tracker.allMet, isTrue);
      tracker.onEscape();
      expect(tracker.anyFailed, isFalse);
      tracker.onEscape();
      expect(tracker.anyFailed, isTrue);
      expect(tracker.progressLabel(0), '2/1');
    });

    test('boss objective completes on defeat', () {
      final tracker = ObjectiveTracker(const [
        ObjectiveDefinition(type: ObjectiveType.defeatBoss),
      ]);
      expect(tracker.allMet, isFalse);
      tracker.onBossDefeated();
      expect(tracker.allMet, isTrue);
    });
  });
}
