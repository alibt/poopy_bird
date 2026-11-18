/// Tunable gameplay constants. Keep magic numbers here, not in components.
abstract final class GameConfig {
  // Bird — cruise-and-hop, not frantic flap-to-survive.
  static const double birdSize = 72;

  /// Light gravity; the bird mostly settles to [cruise] rather than plummeting.
  static const double gravity = 140;

  /// Hop up into the food band. Mild so one flap is a grab, not a panic climb.
  static const double flapVelocity = -220;
  static const double flapCooldown = 0.18;

  /// Soft pull toward the current cruise altitude (px/s²).
  static const double cruiseSettle = 260;

  /// Seconds after a flap before settle-down toward cruise kicks in.
  static const double flapHangTime = 0.35;

  /// Gentle vertical bob on cruise so aiming isn't a static hover.
  static const double cruiseBobAmplitude = 10;
  static const double cruiseBobHz = 0.55;

  // Dive-bomb — hold lower control side / ArrowDown to dive under cruise.
  static const double diveAccel = 900;
  static const double diveMaxSpeed = 420;

  /// How far below cruise counts as an active dive-bomb.
  static const double diveEngagePadding = 18;

  /// Wider multi-splat when dive-bombing (even for normal poops).
  static const double diveSplatReach = 130;

  /// Score multiplier on hits landed while dive-bombing.
  static const double diveScoreBonus = 1.5;

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
  static const double bigSplatReach = 90;

  // Belly (ammo)
  static const int bellyCapacity = 6;

  /// Seconds to digest one poop back into the belly.
  static const double digestionInterval = 3;

  // Food — only in the max-altitude hop band.
  static const double foodSpawnMinInterval = 5;
  static const double foodSpawnMaxInterval = 9;
  static const int berriesAmmo = 3;
  static const double chiliDuration = 5;
  static const int burritoBigPoops = 3;

  // World
  /// Fraction of the screen height taken by the road, measured from the bottom.
  /// Higher = closer framing so cars read larger.
  static const double roadHeightFraction = 0.48;

  /// Where each lane's cars stand, as a fraction of road height from the road
  /// top. Symmetric around 0.5 so the dashed divider sits in the visual center.
  static const List<double> laneBaselines = [0.30, 0.70];

  // Cars
  /// Minimum empty space between two cars in the same lane at spawn time.
  static const double minCarGap = 200;

  // Difficulty ramp: values move from start to end over [rampDuration].
  static const double rampDuration = 180;
  static const double scrollSpeedStart = 130;
  static const double scrollSpeedEnd = 210;
  static const double carSpawnIntervalStart = 2;
  static const double carSpawnIntervalEnd = 0.9;

  /// Cars drive toward the bird; their screen speed is the scroll speed plus
  /// a random ground speed up to this value. Keep mins high so traffic never
  /// looks parked relative to the road.
  static const double carGroundSpeedStart = 90;
  static const double carGroundSpeedEnd = 170;

  /// Within a timed level, scroll speed grows by this fraction by the end.
  static const double levelScrollSpeedRamp = 0.35;

  // Altitude (0 = high cruise, 1 = forced low near the road).
  /// Missed escaping car — big drop.
  static const double altitudePressurePerEscape = 0.18;

  /// Successful splat lifts cruise a little.
  static const double altitudePressurePerHit = 0.07;

  /// Slow sink over a long run (pressure per second).
  static const double altitudePressurePerSecond = 0.008;

  /// Food band as a fraction of screen height from the top.
  static const double foodBandTopFraction = 0.08;
  static const double foodBandBottomFraction = 0.22;

  /// Highest cruise (when pressure is 0), as a fraction of screen height.
  static const double cruiseHighFraction = 0.32;

  /// Lowest cruise (when pressure is 1), just above the road.
  static const double cruiseLowFraction = 0.58;

  /// Bird below this fraction of the sky (from top) can be shot by attackers.
  static const double attackerDangerFraction = 0.55;

  // Scoring
  /// Bonus for defeating a boss.
  static const int bossBonus = 1000;

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
