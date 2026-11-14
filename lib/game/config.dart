/// Tunable gameplay constants. Keep magic numbers here, not in components.
abstract final class GameConfig {
  // Bird
  static const double birdSize = 60;
  static const double gravity = 400;
  static const double flapVelocity = -300;
  static const double flapCooldown = 0.15;

  // Poop
  static const double poopCooldown = 0.5;
  static const double rapidFireCooldown = 0.12;
  static const double poopRadius = 10;
  static const double bigPoopRadius = 18;
  static const double poopGravity = 600;

  /// A poop leaves at least this fast, even when the bird is climbing.
  static const double poopMinDropSpeed = 60;

  /// A diving bird can throw poop at most this fast.
  static const double poopMaxDropSpeed = 400;

  /// A big poop also splats cars whose centre is within this horizontal
  /// distance of the impact, in any lane.
  static const double bigSplatReach = 70;

  // Belly (ammo)
  static const int bellyCapacity = 6;

  /// Seconds to digest one poop back into the belly.
  static const double digestionInterval = 3;

  // Food
  static const double foodSpawnMinInterval = 5;
  static const double foodSpawnMaxInterval = 9;
  static const int berriesAmmo = 3;
  static const double chiliDuration = 5;
  static const int burritoBigPoops = 3;

  // World
  /// Fraction of the screen height taken by the road, measured from the bottom.
  static const double roadHeightFraction = 0.4;

  /// Where each lane's cars stand, as a fraction of road height from the road
  /// top. Lane 0 is the far lane, the last lane is nearest the viewer.
  static const List<double> laneBaselines = [0.42, 0.9];

  // Cars
  /// Minimum empty space between two cars in the same lane at spawn time.
  static const double minCarGap = 170;

  // Difficulty ramp: values move from start to end over [rampDuration].
  static const double rampDuration = 180;
  static const double scrollSpeedStart = 120;
  static const double scrollSpeedEnd = 190;
  static const double carSpawnIntervalStart = 2;
  static const double carSpawnIntervalEnd = 0.9;

  /// Cars drive toward the bird; their screen speed is the scroll speed plus
  /// a random ground speed up to this value.
  static const double carGroundSpeedStart = 100;
  static const double carGroundSpeedEnd = 160;

  // Scoring
  static const int pointsPerSplat = 50;

  /// Scrolled pixels needed to earn one distance point.
  static const double pixelsPerDistancePoint = 10;

  // Combo
  /// Seconds after a splat before the combo expires.
  static const double comboWindow = 2.5;
  static const int maxComboMultiplier = 5;

  // Rage
  static const double rageFillPerEscape = 0.2;
  static const double rageDrainPerSplat = 0.1;
}
