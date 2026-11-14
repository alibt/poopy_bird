import 'dart:math';

import '../game/config.dart';

/// Consecutive splats build a combo; the multiplier is the combo count,
/// capped at [maxMultiplier]. A miss or waiting longer than [window] after
/// the last splat ends it.
class ComboTracker {
  ComboTracker({
    this.window = GameConfig.comboWindow,
    this.maxMultiplier = GameConfig.maxComboMultiplier,
  });

  final double window;
  final int maxMultiplier;

  int count = 0;

  /// Longest combo this run.
  int best = 0;

  double _timeLeft = 0;

  int get multiplier => count == 0 ? 1 : min(count, maxMultiplier);

  /// 1 right after a splat, falling to 0 as the combo is about to expire.
  double get timeLeftFraction => count == 0 ? 0 : _timeLeft / window;

  /// Records a splat and returns the multiplier it earned.
  int registerHit() {
    count++;
    best = max(best, count);
    _timeLeft = window;
    return multiplier;
  }

  void registerMiss() {
    count = 0;
    _timeLeft = 0;
  }

  void update(double dt) {
    if (count == 0) return;
    _timeLeft -= dt;
    if (_timeLeft <= 0) registerMiss();
  }

  void reset() {
    registerMiss();
    best = 0;
  }
}
