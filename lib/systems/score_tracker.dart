import '../game/config.dart';

/// Tracks the current run's score and the best score.
///
/// Distance is accumulated as a double and converted to points on read, so
/// small per-frame increments are never lost to rounding.
class ScoreTracker {
  ScoreTracker({
    this.pixelsPerDistancePoint = GameConfig.pixelsPerDistancePoint,
    this.best = 0,
  });

  final double pixelsPerDistancePoint;

  int best;
  int carsSplatted = 0;

  /// Whether the last finished run beat the previous best.
  bool isNewBest = false;

  int _splatPoints = 0;
  double _distance = 0;

  int get score => _splatPoints + (_distance / pixelsPerDistancePoint).floor();

  void addDistance(double pixels) => _distance += pixels;

  /// Distance flown in metres (one metre per distance point).
  int get distanceMetres => (_distance / pixelsPerDistancePoint).floor();

  /// Records a poop hit worth [basePoints] and returns the points earned.
  int registerHit({required int basePoints, int multiplier = 1}) {
    final points = basePoints * multiplier;
    _splatPoints += points;
    return points;
  }

  /// Adds a bonus such as a boss reward.
  void addBonus(int points) => _splatPoints += points;

  /// Counts a car as fully splatted.
  void registerCarSplatted() => carsSplatted++;

  /// Call once when a run ends.
  void finishRun() {
    isNewBest = score > best;
    if (isNewBest) best = score;
  }

  /// Clears the current run. The best score is kept.
  void reset() {
    carsSplatted = 0;
    _splatPoints = 0;
    _distance = 0;
    isNewBest = false;
  }
}
