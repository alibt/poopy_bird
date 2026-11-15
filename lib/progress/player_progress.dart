import 'dart:math';

import '../levels/level_definition.dart';
import 'level_result.dart';

/// Best result so far on one level.
class LevelRecord {
  const LevelRecord({this.bestStars = 0, this.bestScore = 0, this.plays = 0});

  final int bestStars;
  final int bestScore;
  final int plays;

  bool get completed => bestStars > 0;

  LevelRecord merge(LevelResult result) => LevelRecord(
        bestStars: max(bestStars, result.stars),
        bestScore: max(bestScore, result.score),
        plays: plays + 1,
      );

  factory LevelRecord.fromJson(Map<String, dynamic> json) => LevelRecord(
        bestStars: json['bestStars'] as int? ?? 0,
        bestScore: json['bestScore'] as int? ?? 0,
        plays: json['plays'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'bestStars': bestStars,
        'bestScore': bestScore,
        'plays': plays,
      };
}

/// Everything the player has achieved. Immutable; [withResult] returns an
/// updated copy. Serialised with [schemaVersion] so stored or synced data can
/// be migrated.
class PlayerProgress {
  const PlayerProgress({this.levels = const {}, this.endlessBest = 0});

  static const int schemaVersion = 1;

  final Map<String, LevelRecord> levels;
  final int endlessBest;

  LevelRecord recordFor(String levelId) =>
      levels[levelId] ?? const LevelRecord();

  int get totalStars =>
      levels.values.fold(0, (sum, record) => sum + record.bestStars);

  int starsIn(WorldDefinition world) =>
      world.levelIds.fold(0, (sum, id) => sum + recordFor(id).bestStars);

  bool isWorldComplete(WorldDefinition world) =>
      world.levelIds.isNotEmpty &&
      world.levelIds.every((id) => recordFor(id).completed);

  PlayerProgress withResult(LevelResult result) {
    if (result.isEndless) {
      return PlayerProgress(
        levels: levels,
        endlessBest: max(endlessBest, result.score),
      );
    }
    return PlayerProgress(
      levels: {
        ...levels,
        result.levelId: recordFor(result.levelId).merge(result)
      },
      endlessBest: endlessBest,
    );
  }

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int? ?? 1;
    if (version > schemaVersion) {
      throw FormatException(
          'Progress schema $version is newer than $schemaVersion');
    }
    return PlayerProgress(
      levels: {
        for (final e in (json['levels'] as Map<String, dynamic>? ?? {}).entries)
          e.key: LevelRecord.fromJson(e.value as Map<String, dynamic>),
      },
      endlessBest: json['endlessBest'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'levels': {for (final e in levels.entries) e.key: e.value.toJson()},
        'endlessBest': endlessBest,
      };
}

/// Which worlds, levels and modes the player may play.
class UnlockRules {
  const UnlockRules(this.worlds, this.progress, {this.unlockAll = false});

  final List<WorldDefinition> worlds;
  final PlayerProgress progress;

  /// Debug switch to open everything for testing.
  final bool unlockAll;

  /// A world opens when the previous world is complete.
  bool isWorldUnlocked(WorldDefinition world) {
    if (world.comingSoon) return false;
    if (unlockAll) return true;
    final index = worlds.indexOf(world);
    return index <= 0 || progress.isWorldComplete(worlds[index - 1]);
  }

  /// A level opens when the one before it in its world has been beaten.
  bool isLevelUnlocked(WorldDefinition world, int levelIndex) {
    if (!isWorldUnlocked(world)) return false;
    if (unlockAll || levelIndex == 0) return true;
    return progress.recordFor(world.levelIds[levelIndex - 1]).completed;
  }

  /// Endless opens once the first world is complete.
  bool get isEndlessUnlocked =>
      unlockAll ||
      (worlds.isNotEmpty && progress.isWorldComplete(worlds.first));
}
