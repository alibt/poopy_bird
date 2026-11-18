import 'dart:math';

/// How a run ended.
enum RunOutcome {
  won,
  crashed,
  rageOut,

  /// Time ran out before the objectives were met.
  timeUp,

  /// An objective that can fail (e.g. max escapes) was failed.
  objectiveFailed;

  bool get isWin => this == won;
}

/// The record of one finished run. The game produces it; the app layer
/// stores it and, later, uploads it to the backend.
class LevelResult {
  const LevelResult({
    required this.levelId,
    required this.levelVersion,
    required this.outcome,
    required this.stars,
    required this.score,
    required this.carsSplatted,
    required this.bestCombo,
    required this.escapes,
    required this.durationSeconds,
    required this.finishedAt,
    this.isBoss = false,
    this.runId = '',
    this.rulesVersion = currentRulesVersion,
    this.distance = 0,
    this.poopsDropped = 0,
    this.poopsMissed = 0,
    this.foodEaten = 0,
    this.bossesDefeated = 0,
    this.maxRage = 0,
    this.bestMultiSplat = 0,
    this.splatsByType = const {},
  });

  /// Bump when scoring rules change, so leaderboards can keep scores from
  /// different rules apart.
  static const int currentRulesVersion = 1;

  /// A random id for de-duplicating uploads.
  static String newRunId([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(
        16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Level id, or [endlessId] for Endless runs.
  final String levelId;
  final int levelVersion;
  final RunOutcome outcome;
  final int stars;
  final int score;
  final int carsSplatted;
  final int bestCombo;
  final int escapes;
  final double durationSeconds;
  final DateTime finishedAt;

  /// Whether the level was a boss level (earns a first-clear bonus).
  final bool isBoss;

  final String runId;
  final int rulesVersion;

  /// Distance flown, in metres.
  final int distance;
  final int poopsDropped;
  final int poopsMissed;
  final int foodEaten;
  final int bossesDefeated;

  /// Highest rage reached, 0 to 1.
  final double maxRage;

  /// Most cars splatted by one poop.
  final int bestMultiSplat;

  /// Fully splatted cars per car type name.
  final Map<String, int> splatsByType;

  static const String endlessId = 'endless';

  bool get isEndless => levelId == endlessId;

  factory LevelResult.fromJson(Map<String, dynamic> json) => LevelResult(
        levelId: json['levelId'] as String,
        levelVersion: json['levelVersion'] as int,
        outcome: RunOutcome.values.byName(json['outcome'] as String),
        stars: json['stars'] as int,
        score: json['score'] as int,
        carsSplatted: json['carsSplatted'] as int,
        bestCombo: json['bestCombo'] as int,
        escapes: json['escapes'] as int,
        durationSeconds: (json['durationSeconds'] as num).toDouble(),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        isBoss: json['isBoss'] as bool? ?? false,
        runId: json['runId'] as String? ?? '',
        rulesVersion: json['rulesVersion'] as int? ?? 1,
        distance: json['distance'] as int? ?? 0,
        poopsDropped: json['poopsDropped'] as int? ?? 0,
        poopsMissed: json['poopsMissed'] as int? ?? 0,
        foodEaten: json['foodEaten'] as int? ?? 0,
        bossesDefeated: json['bossesDefeated'] as int? ?? 0,
        maxRage: (json['maxRage'] as num? ?? 0).toDouble(),
        bestMultiSplat: json['bestMultiSplat'] as int? ?? 0,
        splatsByType: {
          for (final e
              in (json['splatsByType'] as Map<String, dynamic>? ?? {}).entries)
            e.key: e.value as int,
        },
      );

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'levelVersion': levelVersion,
        'outcome': outcome.name,
        'stars': stars,
        'score': score,
        'carsSplatted': carsSplatted,
        'bestCombo': bestCombo,
        'escapes': escapes,
        'durationSeconds': durationSeconds,
        'finishedAt': finishedAt.toUtc().toIso8601String(),
        'isBoss': isBoss,
        'runId': runId,
        'rulesVersion': rulesVersion,
        'distance': distance,
        'poopsDropped': poopsDropped,
        'poopsMissed': poopsMissed,
        'foodEaten': foodEaten,
        'bossesDefeated': bossesDefeated,
        'maxRage': maxRage,
        'bestMultiSplat': bestMultiSplat,
        'splatsByType': splatsByType,
      };
}
