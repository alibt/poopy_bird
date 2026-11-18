import 'dart:ui' show lerpDouble;

import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'food_pickup.dart';

/// Food only appears in the max-altitude hop band — flap up to grab it.
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
    final top = game.foodBandTop + 8;
    final bottom = game.foodBandBottom;
    final y = top + game.random.nextDouble() * (bottom - top).clamp(8.0, 999);
    final food = FoodPickup(type: type, position: Vector2(game.size.x + 30, y));
    game.world.add(food);
    return food;
  }
}
