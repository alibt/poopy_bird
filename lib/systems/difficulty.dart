import 'dart:math';
import 'dart:ui' show lerpDouble;

import '../game/config.dart';

/// Ramps the challenge up over the course of a run.
class Difficulty {
  Difficulty({this.rampDuration = GameConfig.rampDuration});

  final double rampDuration;

  double elapsed = 0;

  /// 0 at the start of a run, 1 once fully ramped.
  double get progress => min(elapsed / rampDuration, 1);

  double get scrollSpeed => _lerp(
        GameConfig.scrollSpeedStart,
        GameConfig.scrollSpeedEnd,
      );

  double get carSpawnInterval => _lerp(
        GameConfig.carSpawnIntervalStart,
        GameConfig.carSpawnIntervalEnd,
      );

  double get carGroundSpeedMax => _lerp(
        GameConfig.carGroundSpeedStart,
        GameConfig.carGroundSpeedEnd,
      );

  void update(double dt) => elapsed += dt;

  void reset() => elapsed = 0;

  double _lerp(double start, double end) => lerpDouble(start, end, progress)!;
}
