import 'dart:math';

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import 'car.dart';

/// Sends cars in from the right at the current difficulty's rate, never
/// letting cars in the same lane overlap.
class CarSpawner extends Component with HasGameReference<PoopyBirdGame> {
  final Map<int, Car> _lastInLane = {};
  double _untilNext = 0;

  @override
  Future<void> onLoad() async => reset();

  void reset() {
    _lastInLane.clear();
    _untilNext = game.difficulty.carSpawnInterval;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _untilNext -= dt;
    if (_untilNext > 0) return;
    _untilNext += game.difficulty.carSpawnInterval;
    trySpawn();
  }

  /// Spawns a car in a random lane that has room. Returns null if every lane
  /// is too crowded right now.
  Car? trySpawn() {
    final lanes = [for (var i = 0; i < GameConfig.laneBaselines.length; i++) i]
      ..shuffle(game.random);
    for (final lane in lanes) {
      final car = _spawnInLane(lane);
      if (car != null) return car;
    }
    return null;
  }

  Car? _spawnInLane(int lane) {
    var speed = game.scrollSpeed +
        game.random.nextDouble() * game.difficulty.carGroundSpeedMax;

    final ahead = _lastInLane[lane];
    if (ahead != null && !ahead.isRemoving && !ahead.isRemoved) {
      final gap = game.size.x - (ahead.position.x + ahead.size.x);
      if (gap < GameConfig.minCarGap) return null;
      // Never drive faster than the car ahead, so lanes can't overlap.
      speed = min(speed, ahead.speed);
    }

    final car = Car(
      type: CarType.sedan,
      lane: lane,
      speed: speed,
      position: Vector2(game.size.x, game.laneBaseline(lane)),
    );
    _lastInLane[lane] = car;
    game.world.add(car);
    return car;
  }
}
