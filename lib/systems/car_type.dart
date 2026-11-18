/// Every kind of car in the game. Level files refer to these by [name]
/// (e.g. "sportsCar"), so renaming a value breaks level data.
enum CarType {
  sedan(points: 50, width: 80, height: 50, bodyAsset: 'car_sedan.png'),

  sportsCar(
    points: 100,
    width: 84,
    height: 46,
    bodyAsset: 'car_sports.png',
    groundSpeedBonus: 70,
  ),

  convertible(
    points: 100,
    width: 82,
    height: 44,
    bodyAsset: 'car_convertible.png',
  ),

  /// Freshly washed — sparkling, worth triple.
  washed(
    points: 150,
    width: 80,
    height: 50,
    bodyAsset: 'car_washed.png',
  ),

  bus(
    points: 40,
    width: 140,
    height: 70,
    bodyAsset: 'car_bus.png',
    hitPoints: 3,
  ),

  taxi(
    points: 75,
    width: 80,
    height: 50,
    bodyAsset: 'car_taxi.png',
    groundSpeedBonus: 20,
  ),

  weddingLimo(
    points: 200,
    width: 160,
    height: 52,
    bodyAsset: 'car_limo.png',
    hitPoints: 2,
  ),

  /// Hitting a police car adds rage instead of draining it.
  police(
    points: 60,
    width: 82,
    height: 50,
    bodyAsset: 'car_police.png',
    raisesRageOnHit: true,
  ),

  sunroof(
    points: 120,
    width: 80,
    height: 52,
    bodyAsset: 'car_sunroof.png',
  ),

  /// World 1 boss. Takes several hits and washes nearby splatted cars clean.
  carWashTruck(
    points: 100,
    width: 210,
    height: 100,
    hitPoints: 8,
    isBoss: true,
    bodyAsset: 'boss_car_wash.png',
    wheelsInSprite: true,
  ),

  /// World 2 boss — a stubborn downtown bus.
  rushHourBus(
    points: 80,
    width: 180,
    height: 90,
    hitPoints: 7,
    isBoss: true,
    bodyAsset: 'car_bus.png',
  ),

  /// World 3 boss — the mayor's armored limo (weak-spot timing comes later).
  mayorLimo(
    points: 120,
    width: 220,
    height: 70,
    hitPoints: 10,
    isBoss: true,
    bodyAsset: 'boss_mayor_limo.png',
    wheelsInSprite: true,
  ),

  /// World 4 boss — beach wedding limo that just keeps going.
  boardwalkLimo(
    points: 150,
    width: 200,
    height: 60,
    hitPoints: 8,
    isBoss: true,
    bodyAsset: 'car_limo.png',
  ),

  /// World 5 final boss.
  monsterTruck(
    points: 150,
    width: 200,
    height: 120,
    hitPoints: 12,
    isBoss: true,
    bodyAsset: 'boss_monster_truck.png',
    wheelsInSprite: true,
  );

  const CarType({
    required this.points,
    required this.width,
    required this.height,
    this.bodyAsset,
    this.hitPoints = 1,
    this.groundSpeedBonus = 0,
    this.isBoss = false,
    this.raisesRageOnHit = false,
    this.wheelsInSprite = false,
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

  final bool isBoss;

  /// Splat fills rage instead of draining it.
  final bool raisesRageOnHit;

  /// Boss sprites that already include wheels — skip tire.png.
  final bool wheelsInSprite;

  static CarType parse(String name) {
    for (final type in values) {
      if (type.name == name) return type;
    }
    throw FormatException('Unknown car type "$name"');
  }
}
