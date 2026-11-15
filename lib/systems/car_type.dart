/// Every kind of car in the game. Level files refer to these by [name]
/// (e.g. "sportsCar"), so renaming a value breaks level data.
enum CarType {
  sedan(points: 50, width: 80, height: 50, bodyAsset: 'car-body.png'),

  /// Fast and worth double. Placeholder art: the sedan, hue-shifted yellow.
  sportsCar(
    points: 100,
    width: 84,
    height: 46,
    bodyAsset: 'car-body.png',
    groundSpeedBonus: 70,
    hueShift: 55,
  ),

  /// World 1 boss. Takes several hits and washes nearby splatted cars clean.
  carWashTruck(
      points: 100, width: 210, height: 100, hitPoints: 8, isBoss: true);

  const CarType({
    required this.points,
    required this.width,
    required this.height,
    this.bodyAsset,
    this.hitPoints = 1,
    this.groundSpeedBonus = 0,
    this.hueShift = 0,
    this.isBoss = false,
  });

  /// Base points per hit, before the combo multiplier.
  final int points;
  final double width;

  /// Total height including the wheels.
  final double height;

  /// Sprite for the body, or null if the car draws itself.
  final String? bodyAsset;

  /// Hits needed to fully splat the car.
  final int hitPoints;

  /// Extra ground speed on top of the lane's traffic speed.
  final double groundSpeedBonus;

  /// Degrees to rotate the body sprite's hue (placeholder variants).
  final double hueShift;

  final bool isBoss;

  static CarType parse(String name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    throw FormatException('Unknown car type "$name"');
  }
}
