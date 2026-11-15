import 'dart:ui' show lerpDouble;

import '../game/config.dart';
import '../systems/car_type.dart';
import '../systems/difficulty.dart';
import 'level_definition.dart';

/// Everything a run needs to know about its rules over time. A level plays a
/// [LevelDefinition]; Endless ramps up forever.
abstract interface class RunPlan {
  /// The level being played, or null in Endless.
  LevelDefinition? get level;

  double scrollSpeedAt(double t);

  /// Random traffic at time [t], or null for none.
  TrafficSegment? trafficAt(double t);

  List<ScriptedSpawn> get scriptedSpawns;
  FoodSettings get food;
  double get rageFillPerEscape;

  /// Seconds until the run ends, or null for no limit.
  double? get timeLimit;
  List<ObjectiveDefinition> get objectives;
  bool get endWhenObjectivesMet;
}

class LevelPlan implements RunPlan {
  LevelPlan(this.definition);

  final LevelDefinition definition;

  @override
  LevelDefinition get level => definition;

  @override
  double scrollSpeedAt(double t) => definition.scrollSpeed;

  @override
  TrafficSegment? trafficAt(double t) {
    for (final segment in definition.traffic) {
      if (segment.covers(t)) return segment;
    }
    return null;
  }

  @override
  List<ScriptedSpawn> get scriptedSpawns => definition.scriptedSpawns;

  @override
  FoodSettings get food => definition.food;

  @override
  double get rageFillPerEscape => definition.rageFillPerEscape;

  @override
  double get timeLimit => definition.timeLimit;

  @override
  List<ObjectiveDefinition> get objectives => definition.objectives;

  @override
  bool get endWhenObjectivesMet => definition.endWhenObjectivesMet;
}

/// Endless mode: no time limit, difficulty ramps with [Difficulty].
class EndlessPlan implements RunPlan {
  EndlessPlan({Difficulty? difficulty})
      : _difficulty = difficulty ?? Difficulty();

  final Difficulty _difficulty;

  /// Sports cars start appearing once the ramp passes this point.
  static const double _sportsCarsFrom = 0.3;

  @override
  LevelDefinition? get level => null;

  @override
  double scrollSpeedAt(double t) => (_difficulty..elapsed = t).scrollSpeed;

  @override
  TrafficSegment trafficAt(double t) {
    _difficulty.elapsed = t;
    final sportsWeight = (lerpDouble(0, 3,
            (_difficulty.progress - _sportsCarsFrom) / (1 - _sportsCarsFrom))!)
        .clamp(0, 3)
        .round();
    return TrafficSegment(
      from: t,
      to: double.infinity,
      interval: _difficulty.carSpawnInterval,
      groundSpeedMin: 0,
      groundSpeedMax: _difficulty.carGroundSpeedMax,
      cars: {
        CarType.sedan: 6,
        if (sportsWeight > 0) CarType.sportsCar: sportsWeight,
      },
    );
  }

  @override
  List<ScriptedSpawn> get scriptedSpawns => const [];

  @override
  FoodSettings get food => const FoodSettings(
        minInterval: GameConfig.foodSpawnMinInterval,
        maxInterval: GameConfig.foodSpawnMaxInterval,
      );

  @override
  double get rageFillPerEscape => GameConfig.rageFillPerEscape;

  @override
  double? get timeLimit => null;

  @override
  List<ObjectiveDefinition> get objectives => const [];

  @override
  bool get endWhenObjectivesMet => false;
}
