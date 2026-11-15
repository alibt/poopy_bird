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
  });

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
      };
}
