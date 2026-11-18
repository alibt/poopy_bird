import 'dart:math';

import 'car_type.dart';

/// Counters for one run that feed achievements and analytics. Scores,
/// combos and objectives have their own trackers; this holds the rest.
class RunStats {
  int poopsDropped = 0;
  int poopsMissed = 0;
  int foodEaten = 0;
  int bossesDefeated = 0;

  /// Highest rage reached, 0 to 1.
  double maxRage = 0;

  /// Most cars splatted by a single poop.
  int bestMultiSplat = 0;

  /// Fully splatted cars per [CarType.name].
  final Map<String, int> splatsByType = {};

  void onPoopDropped() => poopsDropped++;
  void onPoopMissed() => poopsMissed++;
  void onFoodEaten() => foodEaten++;
  void onRage(double value) => maxRage = max(maxRage, value);
  void onPoopLanded(int carsSplatted) =>
      bestMultiSplat = max(bestMultiSplat, carsSplatted);

  void onCarSplatted(CarType type) {
    splatsByType.update(type.name, (n) => n + 1, ifAbsent: () => 1);
    if (type.isBoss) bossesDefeated++;
  }

  void reset() {
    poopsDropped = 0;
    poopsMissed = 0;
    foodEaten = 0;
    bossesDefeated = 0;
    maxRage = 0;
    bestMultiSplat = 0;
    splatsByType.clear();
  }
}
