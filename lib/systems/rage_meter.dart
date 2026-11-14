import 'dart:math';

import '../game/config.dart';

/// How angry the city is, from 0 (calm) to 1 (game over).
///
/// Cars that escape clean raise it; splatting a car lowers it.
class RageMeter {
  RageMeter({
    this.fillPerEscape = GameConfig.rageFillPerEscape,
    this.drainPerSplat = GameConfig.rageDrainPerSplat,
  });

  final double fillPerEscape;
  final double drainPerSplat;

  // Tolerates floating point drift, e.g. 0.2 * 5 not being exactly 1.0.
  static const double _epsilon = 1e-9;

  double _value = 0;

  double get value => _value;
  bool get isFull => _value >= 1 - _epsilon;

  void onCarEscaped() => _value = min(1, _value + fillPerEscape);

  void onCarSplatted() => _value = max(0, _value - drainPerSplat);

  void reset() => _value = 0;
}
