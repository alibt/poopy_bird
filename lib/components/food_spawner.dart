import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'food_pickup.dart';

/// Sends food in from the right. Spawn height follows altitude pressure so
/// ammo stays reachable when the bird is forced lower — with rooftop snacks
/// as a riskier dive option near the road.
class FoodSpawner extends Component with HasGameReference<PoopyBirdGame> {
  double _untilNext = 0;

  @override
  Future<void> onLoad() async => reset();

  void reset() => _untilNext = _nextInterval();

  double _nextInterval() {
    final food = game.plan.food;
    return lerpDouble(
        food.minInterval, food.maxInterval, game.random.nextDouble())!;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final types = game.plan.food.types;
    if (types.isEmpty) return;
    _untilNext -= dt;
    if (_untilNext > 0) return;
    _untilNext = _nextInterval();
    spawn(FoodType.pick(game.random.nextDouble(), from: types));
  }

  FoodPickup spawn(FoodType type) {
    final pressure = game.altitudePressure;
    final rooftop = game.random.nextDouble() < GameConfig.rooftopFoodChance;
    final double y;
    if (rooftop) {
      // Just above the far lane — dive for it, but stay above car roofs.
      y = game.roadTop - 28 - game.random.nextDouble() * 18;
    } else {
      // Band sinks with pressure so food stays in the flyable corridor.
      final skyTop = game.size.y * 0.12;
      final bandTop = lerpDouble(skyTop, game.roadTop - 140, pressure * 0.75)!;
      final bandBottom =
          lerpDouble(game.roadTop - 90, game.roadTop - 40, pressure)!;
      final lo = min(bandTop, bandBottom);
      final hi = max(bandTop, bandBottom);
      y = lo + game.random.nextDouble() * max(8.0, hi - lo);
    }
    final food = FoodPickup(type: type, position: Vector2(game.size.x + 30, y));
    game.world.add(food);
    return food;
  }
}
