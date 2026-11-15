import 'dart:math';

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import '../levels/level_definition.dart';
import 'car.dart';
import 'car_wash_truck.dart';

/// Spawns traffic from the run plan: random cars per the current traffic
/// segment, plus scripted spawns (e.g. bosses) at set times. Cars in the same
/// lane never overlap.
class CarSpawner extends Component with HasGameReference<PoopyBirdGame> {
  final Map<int, Car> _lastInLane = {};
  late List<ScriptedSpawn> _scripted;
  int _nextScripted = 0;
  double _untilNext = 0;

  @override
  Future<void> onLoad() async => reset();

  void reset() {
    _lastInLane.clear();
    _scripted = [...game.plan.scriptedSpawns]
      ..sort((a, b) => a.at.compareTo(b.at));
    _nextScripted = 0;
    _untilNext = game.plan.trafficAt(0)?.interval ?? 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final t = game.elapsed;

    // Scripted spawns wait for room in their lane rather than being dropped.
    while (
        _nextScripted < _scripted.length && _scripted[_nextScripted].at <= t) {
      final s = _scripted[_nextScripted];
      final car = _spawn(
        s.car,
        s.lane,
        game.scrollSpeed + s.groundSpeed + s.car.groundSpeedBonus,
      );
      if (car == null) break;
      _nextScripted++;
    }

    final traffic = game.plan.trafficAt(t);
    if (traffic == null) return;
    _untilNext -= dt;
    if (_untilNext > 0) return;
    _untilNext = traffic.interval;
    trySpawn(traffic);
  }

  /// Spawns a random car from [traffic] in a lane that has room. Returns null
  /// if every allowed lane is too crowded right now.
  Car? trySpawn(TrafficSegment traffic) {
    final random = game.random;
    final type = _pickWeighted(traffic.cars, random.nextDouble());
    final groundSpeed = traffic.groundSpeedMin +
        random.nextDouble() * (traffic.groundSpeedMax - traffic.groundSpeedMin);
    final speed = game.scrollSpeed + groundSpeed + type.groundSpeedBonus;
    for (final lane in [...traffic.lanes]..shuffle(random)) {
      final car = _spawn(type, lane, speed);
      if (car != null) return car;
    }
    return null;
  }

  Car? _spawn(CarType type, int lane, double speed) {
    final ahead = _lastInLane[lane];
    if (ahead != null && !ahead.isRemoving && !ahead.isRemoved) {
      final gap = game.size.x - (ahead.position.x + ahead.size.x);
      if (gap < GameConfig.minCarGap) return null;
      // Never drive faster than the car ahead, so lanes can't overlap.
      speed = min(speed, ahead.speed);
    }

    final position = Vector2(game.size.x, game.laneBaseline(lane));
    final car = switch (type) {
      CarType.carWashTruck =>
        CarWashTruck(lane: lane, speed: speed, position: position),
      _ => Car(type: type, lane: lane, speed: speed, position: position),
    };
    _lastInLane[lane] = car;
    game.world.add(car);
    return car;
  }

  static T _pickWeighted<T>(Map<T, int> weights, double roll) {
    final total = weights.values.fold(0, (a, b) => a + b);
    var target = roll * total;
    for (final entry in weights.entries) {
      target -= entry.value;
      if (target < 0) return entry.key;
    }
    return weights.keys.last;
  }
}
