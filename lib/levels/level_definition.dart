import '../systems/car_type.dart';
import '../systems/food.dart';

/// Reads a JSON field, throwing a [FormatException] that names the field
/// when it is missing or has the wrong type.
T _field<T>(Map<String, dynamic> json, String key, {T? fallback}) {
  final value = json[key];
  if (value == null) {
    if (fallback != null || null is T) return fallback as T;
    throw FormatException('Missing field "$key"');
  }
  if (T == double && value is num) return value.toDouble() as T;
  if (value is! T) {
    throw FormatException(
        'Field "$key" should be $T, got ${value.runtimeType}');
  }
  return value;
}

List<Map<String, dynamic>> _list(Map<String, dynamic> json, String key) =>
    (_field<List<dynamic>>(json, key, fallback: const []))
        .cast<Map<String, dynamic>>();

/// A playable level, loaded from `assets/levels/<id>.json` (and later,
/// possibly from the backend).
class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.version,
    required this.name,
    required this.timeLimit,
    required this.scrollSpeed,
    required this.rageFillPerEscape,
    required this.food,
    required this.traffic,
    required this.scriptedSpawns,
    required this.objectives,
    required this.stars,
    this.isBoss = false,
    this.endWhenObjectivesMet = false,
    this.description = '',
  });

  /// Stable id such as "w1_l3". Used for progress records and results.
  final String id;

  /// Bump when the level's content changes, so results can be matched to
  /// the revision they were played on.
  final int version;

  final String name;
  final String description;

  /// Seconds the level lasts. Objectives are checked when time runs out.
  final double timeLimit;

  final double scrollSpeed;
  final double rageFillPerEscape;
  final FoodSettings food;
  final List<TrafficSegment> traffic;
  final List<ScriptedSpawn> scriptedSpawns;
  final List<ObjectiveDefinition> objectives;
  final StarThresholds stars;
  final bool isBoss;

  /// End with a win as soon as every objective is met (e.g. boss defeated)
  /// instead of waiting for the time limit.
  final bool endWhenObjectivesMet;

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    final id = _field<String>(json, 'id');
    try {
      return LevelDefinition(
        id: id,
        version: _field<int>(json, 'version', fallback: 1),
        name: _field<String>(json, 'name'),
        description: _field<String>(json, 'description', fallback: ''),
        timeLimit: _field<double>(json, 'timeLimit'),
        scrollSpeed: _field<double>(json, 'scrollSpeed'),
        rageFillPerEscape: _field<double>(json, 'rageFillPerEscape'),
        food: FoodSettings.fromJson(
          _field<Map<String, dynamic>>(json, 'food', fallback: const {}),
        ),
        traffic: _list(json, 'traffic').map(TrafficSegment.fromJson).toList(),
        scriptedSpawns:
            _list(json, 'scriptedSpawns').map(ScriptedSpawn.fromJson).toList(),
        objectives: _list(json, 'objectives')
            .map(ObjectiveDefinition.fromJson)
            .toList(),
        stars: StarThresholds.fromJson(
            _field<Map<String, dynamic>>(json, 'stars')),
        isBoss: _field<bool>(json, 'isBoss', fallback: false),
        endWhenObjectivesMet:
            _field<bool>(json, 'endWhenObjectivesMet', fallback: false),
      );
    } on FormatException catch (e) {
      throw FormatException('Level "$id": ${e.message}');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'name': name,
        'description': description,
        'timeLimit': timeLimit,
        'scrollSpeed': scrollSpeed,
        'rageFillPerEscape': rageFillPerEscape,
        'food': food.toJson(),
        'traffic': traffic.map((t) => t.toJson()).toList(),
        'scriptedSpawns': scriptedSpawns.map((s) => s.toJson()).toList(),
        'objectives': objectives.map((o) => o.toJson()).toList(),
        'stars': stars.toJson(),
        'isBoss': isBoss,
        'endWhenObjectivesMet': endWhenObjectivesMet,
      };
}

/// Random traffic between [from] and [to] seconds.
class TrafficSegment {
  const TrafficSegment({
    required this.from,
    required this.to,
    required this.interval,
    required this.groundSpeedMin,
    required this.groundSpeedMax,
    required this.cars,
    this.lanes = const [0, 1],
  });

  final double from;
  final double to;

  /// Seconds between spawn attempts.
  final double interval;
  final double groundSpeedMin;
  final double groundSpeedMax;

  /// Relative spawn weight per car type.
  final Map<CarType, int> cars;
  final List<int> lanes;

  bool covers(double t) => t >= from && t < to;

  factory TrafficSegment.fromJson(Map<String, dynamic> json) {
    final speed = _field<List<dynamic>>(json, 'groundSpeed');
    if (speed.length != 2) {
      throw const FormatException('"groundSpeed" must be [min, max]');
    }
    final cars = _field<Map<String, dynamic>>(json, 'cars');
    if (cars.isEmpty) throw const FormatException('"cars" must not be empty');
    return TrafficSegment(
      from: _field<double>(json, 'from'),
      to: _field<double>(json, 'to'),
      interval: _field<double>(json, 'interval'),
      groundSpeedMin: (speed[0] as num).toDouble(),
      groundSpeedMax: (speed[1] as num).toDouble(),
      cars: {
        for (final entry in cars.entries)
          CarType.parse(entry.key): (entry.value as num).toInt(),
      },
      lanes: _field<List<dynamic>>(json, 'lanes', fallback: const [0, 1])
          .cast<int>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'interval': interval,
        'groundSpeed': [groundSpeedMin, groundSpeedMax],
        'cars': {for (final e in cars.entries) e.key.name: e.value},
        'lanes': lanes,
      };
}

/// A specific car (or boss) that appears at a set time.
class ScriptedSpawn {
  const ScriptedSpawn({
    required this.at,
    required this.car,
    this.lane = 1,
    this.groundSpeed = 0,
  });

  final double at;
  final CarType car;
  final int lane;
  final double groundSpeed;

  factory ScriptedSpawn.fromJson(Map<String, dynamic> json) => ScriptedSpawn(
        at: _field<double>(json, 'at'),
        car: CarType.parse(_field<String>(json, 'car')),
        lane: _field<int>(json, 'lane', fallback: 1),
        groundSpeed: _field<double>(json, 'groundSpeed', fallback: 0),
      );

  Map<String, dynamic> toJson() => {
        'at': at,
        'car': car.name,
        'lane': lane,
        'groundSpeed': groundSpeed,
      };
}

enum ObjectiveType {
  /// Splat [count] cars (optionally only of [carType]).
  splatCars,

  /// Reach a combo of [count].
  reachCombo,

  /// Let at most [count] cars escape clean. Failing this ends the level.
  maxEscapes,

  /// Reach a score of [count].
  reachScore,

  /// Defeat the level's boss.
  defeatBoss,
}

class ObjectiveDefinition {
  const ObjectiveDefinition({
    required this.type,
    this.count = 1,
    this.carType,
  });

  final ObjectiveType type;
  final int count;
  final CarType? carType;

  String get description => switch (type) {
        ObjectiveType.splatCars => carType == null
            ? 'Splat $count cars'
            : 'Splat $count ${_carLabel(carType!)}',
        ObjectiveType.reachCombo => 'Reach a x$count combo',
        ObjectiveType.maxEscapes => count == 0
            ? 'Let no car escape clean'
            : 'Let at most $count cars escape clean',
        ObjectiveType.reachScore => 'Score $count points',
        ObjectiveType.defeatBoss => 'Defeat the boss',
      };

  static String _carLabel(CarType type) => switch (type) {
        CarType.sedan => 'sedans',
        CarType.sportsCar => 'sports cars',
        CarType.carWashTruck => 'car wash trucks',
      };

  factory ObjectiveDefinition.fromJson(Map<String, dynamic> json) {
    final typeName = _field<String>(json, 'type');
    final type = ObjectiveType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => throw FormatException('Unknown objective "$typeName"'),
    );
    final car = _field<String?>(json, 'carType');
    return ObjectiveDefinition(
      type: type,
      count: _field<int>(json, 'count', fallback: 1),
      carType: car == null ? null : CarType.parse(car),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'count': count,
        if (carType != null) 'carType': carType!.name,
      };
}

/// Score needed for two and three stars. One star is earned by winning.
class StarThresholds {
  const StarThresholds({required this.two, required this.three});

  final int two;
  final int three;

  int starsFor({required bool won, required int score}) {
    if (!won) return 0;
    if (score >= three) return 3;
    if (score >= two) return 2;
    return 1;
  }

  factory StarThresholds.fromJson(Map<String, dynamic> json) {
    final stars = StarThresholds(
      two: _field<int>(json, 'two'),
      three: _field<int>(json, 'three'),
    );
    if (stars.three < stars.two) {
      throw const FormatException('Three-star score must be >= two-star score');
    }
    return stars;
  }

  Map<String, dynamic> toJson() => {'two': two, 'three': three};
}

class FoodSettings {
  const FoodSettings({
    this.types = FoodType.values,
    this.minInterval = 5,
    this.maxInterval = 9,
  });

  /// Food that can appear. Empty means no food in this level.
  final List<FoodType> types;
  final double minInterval;
  final double maxInterval;

  factory FoodSettings.fromJson(Map<String, dynamic> json) => FoodSettings(
        types: json['types'] == null
            ? FoodType.values
            : [
                for (final name in (json['types'] as List).cast<String>())
                  FoodType.values.firstWhere(
                    (f) => f.name == name,
                    orElse: () => throw FormatException('Unknown food "$name"'),
                  ),
              ],
        minInterval: _field<double>(json, 'minInterval', fallback: 5),
        maxInterval: _field<double>(json, 'maxInterval', fallback: 9),
      );

  Map<String, dynamic> toJson() => {
        'types': types.map((f) => f.name).toList(),
        'minInterval': minInterval,
        'maxInterval': maxInterval,
      };
}

/// A group of levels with its own setting, e.g. "Suburbs".
class WorldDefinition {
  const WorldDefinition({
    required this.id,
    required this.name,
    required this.levelIds,
    this.comingSoon = false,
  });

  final String id;
  final String name;

  /// In play order; the last one is the boss level.
  final List<String> levelIds;

  /// Listed on the world map but not playable yet.
  final bool comingSoon;

  factory WorldDefinition.fromJson(Map<String, dynamic> json) =>
      WorldDefinition(
        id: _field<String>(json, 'id'),
        name: _field<String>(json, 'name'),
        levelIds: _field<List<dynamic>>(json, 'levels', fallback: const [])
            .cast<String>(),
        comingSoon: _field<bool>(json, 'comingSoon', fallback: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'levels': levelIds,
        'comingSoon': comingSoon,
      };
}
