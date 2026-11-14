/// Tunable gameplay constants. Keep magic numbers here, not in components.
abstract final class GameConfig {
  // Bird
  static const double birdSize = 60;
  static const double gravity = 400;
  static const double flapVelocity = -300;
  static const double flapCooldown = 0.15;
  static const double poopCooldown = 0.5;

  // Poop
  static const double poopRadius = 10;
  static const double poopFallSpeed = 200;

  // World
  static const double scrollSpeed = 120;

  /// Fraction of the screen height taken by the road, measured from the bottom.
  static const double roadHeightFraction = 0.4;

  /// Where each lane's cars stand, as a fraction of road height from the road
  /// top. Lane 0 is the far lane, the last lane is nearest the viewer.
  static const List<double> laneBaselines = [0.42, 0.9];

  // Cars
  static const double carSpawnInterval = 2;
  static const double carMinSpeed = 120;
  static const double carMaxSpeed = 220;

  /// Minimum empty space between two cars in the same lane at spawn time.
  static const double minCarGap = 170;

  // Scoring
  static const int pointsPerSplat = 50;

  /// Scrolled pixels needed to earn one distance point.
  static const double pixelsPerDistancePoint = 10;

  // Rage
  static const double rageFillPerEscape = 0.2;
  static const double rageDrainPerSplat = 0.1;
}
