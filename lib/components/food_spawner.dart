import 'dart:ui' show lerpDouble;

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'food_pickup.dart';

/// Sends food in from the right every few seconds, at a random height in
/// the sky.
class FoodSpawner extends Component with HasGameReference<PoopyBirdGame> {
  double _untilNext = 0;

  @override
  Future<void> onLoad() async => reset();

  void reset() => _untilNext = _nextInterval();

  double _nextInterval() => lerpDouble(
        GameConfig.foodSpawnMinInterval,
        GameConfig.foodSpawnMaxInterval,
        game.random.nextDouble(),
      )!;

  @override
  void update(double dt) {
    super.update(dt);
    _untilNext -= dt;
    if (_untilNext > 0) return;
    _untilNext = _nextInterval();
    spawn(FoodType.pick(game.random.nextDouble()));
  }

  FoodPickup spawn(FoodType type) {
    final top = game.size.y * 0.15;
    final bottom = game.roadTop - 60;
    final y = top + game.random.nextDouble() * (bottom - top);
    final food = FoodPickup(type: type, position: Vector2(game.size.x + 30, y));
    game.world.add(food);
    return food;
  }
}
