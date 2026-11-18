import 'dart:math';

import 'level_result.dart';

/// Totals across every run, for achievements and the Trophy Room.
class LifetimeStats {
  const LifetimeStats({
    this.runs = 0,
    this.wins = 0,
    this.carsSplatted = 0,
    this.poopsDropped = 0,
    this.foodEaten = 0,
    this.bossesDefeated = 0,
    this.bestCombo = 0,
    this.distance = 0,
    this.splatsByType = const {},
  });

  final int runs;
  final int wins;
  final int carsSplatted;
  final int poopsDropped;
  final int foodEaten;
  final int bossesDefeated;
  final int bestCombo;

  /// Metres flown, all modes.
  final int distance;
  final Map<String, int> splatsByType;

  int splatsOf(String carType) => splatsByType[carType] ?? 0;

  LifetimeStats add(LevelResult r) => LifetimeStats(
        runs: runs + 1,
        wins: wins + (r.outcome.isWin ? 1 : 0),
        carsSplatted: carsSplatted + r.carsSplatted,
        poopsDropped: poopsDropped + r.poopsDropped,
        foodEaten: foodEaten + r.foodEaten,
        bossesDefeated: bossesDefeated + r.bossesDefeated,
        bestCombo: max(bestCombo, r.bestCombo),
        distance: distance + r.distance,
        splatsByType: {
          ...splatsByType,
          for (final e in r.splatsByType.entries)
            e.key: splatsOf(e.key) + e.value,
        },
      );

  factory LifetimeStats.fromJson(Map<String, dynamic> json) => LifetimeStats(
        runs: json['runs'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
        carsSplatted: json['carsSplatted'] as int? ?? 0,
        poopsDropped: json['poopsDropped'] as int? ?? 0,
        foodEaten: json['foodEaten'] as int? ?? 0,
        bossesDefeated: json['bossesDefeated'] as int? ?? 0,
        bestCombo: json['bestCombo'] as int? ?? 0,
        distance: json['distance'] as int? ?? 0,
        splatsByType: {
          for (final e
              in (json['splatsByType'] as Map<String, dynamic>? ?? {}).entries)
            e.key: e.value as int,
        },
      );

  Map<String, dynamic> toJson() => {
        'runs': runs,
        'wins': wins,
        'carsSplatted': carsSplatted,
        'poopsDropped': poopsDropped,
        'foodEaten': foodEaten,
        'bossesDefeated': bossesDefeated,
        'bestCombo': bestCombo,
        'distance': distance,
        'splatsByType': splatsByType,
      };
}

/// One entry in the personal Endless top list. Holds what a leaderboard
/// needs: score, distance, when, the run id and the rules version.
class EndlessRun {
  const EndlessRun({
    required this.score,
    required this.distance,
    required this.durationSeconds,
    required this.finishedAt,
    required this.runId,
    required this.rulesVersion,
  });

  factory EndlessRun.from(LevelResult r) => EndlessRun(
        score: r.score,
        distance: r.distance,
        durationSeconds: r.durationSeconds,
        finishedAt: r.finishedAt,
        runId: r.runId,
        rulesVersion: r.rulesVersion,
      );

  final int score;
  final int distance;
  final double durationSeconds;
  final DateTime finishedAt;
  final String runId;
  final int rulesVersion;

  factory EndlessRun.fromJson(Map<String, dynamic> json) => EndlessRun(
        score: json['score'] as int,
        distance: json['distance'] as int? ?? 0,
        durationSeconds: (json['durationSeconds'] as num? ?? 0).toDouble(),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        runId: json['runId'] as String? ?? '',
        rulesVersion: json['rulesVersion'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'distance': distance,
        'durationSeconds': durationSeconds,
        'finishedAt': finishedAt.toUtc().toIso8601String(),
        'runId': runId,
        'rulesVersion': rulesVersion,
      };
}
