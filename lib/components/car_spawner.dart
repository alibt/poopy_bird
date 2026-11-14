import 'dart:math';

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import 'car.dart';

/// Periodically sends cars in from the right, never letting cars in the same
/// lane overlap.
class CarSpawner extends Component with HasGameReference<PoopyBirdGame> {
  final Map<int, Car> _lastInLane = {};
  late final TimerComponent _timer;

  @override
  Future<void> onLoad() async {
    _timer = TimerComponent(
      period: GameConfig.carSpawnInterval,
      repeat: true,
      onTick: trySpawn,
    );
    add(_timer);
  }

  void reset() {
    _lastInLane.clear();
    _timer.timer.reset();
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
    final range = GameConfig.carMaxSpeed - GameConfig.carMinSpeed;
    var speed = GameConfig.carMinSpeed + game.random.nextDouble() * range;

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
