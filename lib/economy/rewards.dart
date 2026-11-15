import 'dart:math';

import '../progress/level_result.dart';
import '../progress/player_progress.dart';

/// Coins earned by one run, broken down for the results screen.
class RunReward {
  const RunReward({
    this.scoreCoins = 0,
    this.winBonus = 0,
    this.newStarCoins = 0,
    this.firstClearBonus = 0,
  });

  final int scoreCoins;
  final int winBonus;

  /// Coins for stars earned on this level for the first time.
  final int newStarCoins;

  /// One-off bonus for beating a boss for the first time.
  final int firstClearBonus;

  int get total => scoreCoins + winBonus + newStarCoins + firstClearBonus;

  static const RunReward none = RunReward();

  Map<String, dynamic> toJson() => {
        'scoreCoins': scoreCoins,
        'winBonus': winBonus,
        'newStarCoins': newStarCoins,
        'firstClearBonus': firstClearBonus,
      };
}

/// How runs turn into coins. Pure, so the backend can apply the same rules
/// to validate a client's claim.
///
/// Tuned so World 1 (all stars plus normal replays) pays for roughly a
/// third of the upgrades; ads and purchases speed that up.
abstract final class RewardRules {
  static const int pointsPerCoin = 100;
  static const int maxScoreCoins = 60;
  static const int endlessPointsPerCoin = 80;
  static const int maxEndlessCoins = 150;
  static const int winBonus = 10;
  static const int coinsPerNewStar = 25;
  static const int bossFirstClearBonus = 150;

  static RunReward forResult(LevelResult result, PlayerProgress before) {
    if (result.isEndless) {
      return RunReward(
        scoreCoins: min(maxEndlessCoins, result.score ~/ endlessPointsPerCoin),
      );
    }
    final previous = before.recordFor(result.levelId);
    final won = result.outcome.isWin;
    final newStars = max(0, result.stars - previous.bestStars);
    return RunReward(
      scoreCoins: min(maxScoreCoins, result.score ~/ pointsPerCoin),
      winBonus: won ? winBonus : 0,
      newStarCoins: newStars * coinsPerNewStar,
      firstClearBonus:
          result.isBoss && won && !previous.completed ? bossFirstClearBonus : 0,
    );
  }
}
