import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/achievements/achievements.dart';
import 'package:poopy_bird/achievements/trophies.dart';
import 'package:poopy_bird/levels/level_definition.dart';
import 'package:poopy_bird/progress/level_result.dart';
import 'package:poopy_bird/progress/lifetime_stats.dart';
import 'package:poopy_bird/progress/player_progress.dart';
import 'package:poopy_bird/progress/progress_repository.dart';
import 'package:poopy_bird/systems/run_stats.dart';
import 'package:poopy_bird/systems/car_type.dart';

LevelResult _run({
  String id = 'w1_l1',
  RunOutcome outcome = RunOutcome.won,
  int stars = 1,
  int score = 500,
  int carsSplatted = 5,
  int bestCombo = 2,
  int escapes = 0,
  double maxRage = 0,
  int poopsDropped = 5,
  int poopsMissed = 0,
  int foodEaten = 0,
  int bossesDefeated = 0,
  int bestMultiSplat = 1,
  Map<String, int> splatsByType = const {},
  double durationSeconds = 40,
  String runId = 'run1',
}) =>
    LevelResult(
      levelId: id,
      levelVersion: 1,
      outcome: outcome,
      stars: stars,
      score: score,
      carsSplatted: carsSplatted,
      bestCombo: bestCombo,
      escapes: escapes,
      durationSeconds: durationSeconds,
      finishedAt: DateTime.utc(2026, 11, 16, 12),
      runId: runId,
      maxRage: maxRage,
      poopsDropped: poopsDropped,
      poopsMissed: poopsMissed,
      foodEaten: foodEaten,
      bossesDefeated: bossesDefeated,
      bestMultiSplat: bestMultiSplat,
      splatsByType: splatsByType,
    );

const _worlds = [
  WorldDefinition(id: 'w1', name: 'Suburbs', levelIds: ['w1_l1', 'w1_l2']),
];

void main() {
  group('RunStats', () {
    test('tracks poops, food, multi-splats and bosses', () {
      final stats = RunStats()
        ..onPoopDropped()
        ..onPoopMissed()
        ..onFoodEaten()
        ..onRage(0.4)
        ..onRage(0.2)
        ..onPoopLanded(3)
        ..onCarSplatted(CarType.sedan)
        ..onCarSplatted(CarType.carWashTruck);
      expect(stats.poopsDropped, 1);
      expect(stats.poopsMissed, 1);
      expect(stats.foodEaten, 1);
      expect(stats.maxRage, 0.4);
      expect(stats.bestMultiSplat, 3);
      expect(stats.splatsByType['sedan'], 1);
      expect(stats.bossesDefeated, 1);
    });
  });

  group('LifetimeStats', () {
    test('adds a run into lifetime totals', () {
      final stats = const LifetimeStats().add(_run(
        carsSplatted: 4,
        bestCombo: 7,
        splatsByType: {'sportsCar': 2},
        bossesDefeated: 1,
      ));
      expect(stats.runs, 1);
      expect(stats.wins, 1);
      expect(stats.carsSplatted, 4);
      expect(stats.bestCombo, 7);
      expect(stats.splatsOf('sportsCar'), 2);
      expect(stats.bossesDefeated, 1);
    });
  });

  group('Achievements', () {
    test('feats unlock from the run just played', () {
      final progress = const PlayerProgress().withResult(_run(bestCombo: 10));
      final earned = Achievements.newlyEarned(AchievementContext(
        progress: progress,
        worlds: _worlds,
        run: _run(bestCombo: 10),
      ));
      expect(earned.map((a) => a.id), containsAll(['combo_5', 'combo_10', 'first_win']));
    });

    test('counters unlock from lifetime totals', () {
      var progress = const PlayerProgress();
      for (var i = 0; i < 100; i++) {
        progress = progress.withResult(_run(carsSplatted: 1, runId: 'r$i'));
      }
      final earned = Achievements.newlyEarned(AchievementContext(
        progress: progress,
        worlds: _worlds,
      ));
      expect(earned.map((a) => a.id), containsAll(['splat_1', 'splat_100']));
    });

    test('zen bird needs a win with low max rage', () {
      final win = _run(maxRage: 0.1, escapes: 0);
      expect(
        Achievements.byId('zen_bird')!
            .isEarned(AchievementContext(
              progress: const PlayerProgress(),
              worlds: _worlds,
              run: win,
            )),
        isTrue,
      );
      expect(
        Achievements.byId('zen_bird')!
            .isEarned(AchievementContext(
              progress: const PlayerProgress(),
              worlds: _worlds,
              run: _run(maxRage: 0.5),
            )),
        isFalse,
      );
    });
  });

  group('Trophies', () {
    test('world cup tiers follow stars earned', () {
      // Complete both levels with one star each → bronze (not yet 2/3 of stars).
      var progress = const PlayerProgress()
          .withResult(_run(id: 'w1_l1', stars: 1))
          .withResult(_run(id: 'w1_l2', stars: 1));
      expect(Trophies.all(progress, _worlds).first.tier, TrophyTier.bronze);

      // 4/6 stars meets the silver threshold (ceil of 2/3).
      progress = progress.withResult(_run(id: 'w1_l1', stars: 3));
      expect(Trophies.all(progress, _worlds).first.tier, TrophyTier.silver);

      progress = progress.withResult(_run(id: 'w1_l2', stars: 3));
      expect(Trophies.all(progress, _worlds).first.tier, TrophyTier.gold);
    });
  });

  group('PlayerProgress achievements and endless top', () {
    test('unlockAchievements pays coins once', () {
      final at = DateTime.utc(2026, 11, 16);
      final progress = const PlayerProgress()
          .unlockAchievements(['first_win', 'first_win', 'nope'], at);
      expect(progress.hasAchievement('first_win'), isTrue);
      expect(progress.coins, Achievements.byId('first_win')!.coins);
      expect(progress.achievements['first_win'], at);
    });

    test('endless top keeps the best ten and ranks by run id', () {
      var progress = const PlayerProgress();
      for (var i = 0; i < 12; i++) {
        progress = progress.withResult(_run(
          id: LevelResult.endlessId,
          stars: 0,
          outcome: RunOutcome.crashed,
          score: i * 100,
          runId: 'e$i',
        ));
      }
      expect(progress.endlessBest, 1100);
      expect(progress.endlessTop, hasLength(10));
      expect(progress.endlessTop.first.score, 1100);
      expect(progress.endlessRankOf('e11'), 1);
      expect(progress.endlessRankOf('e0'), isNull);
    });

    test('schema v3 JSON round trip keeps achievements and top list', () {
      final progress = const PlayerProgress()
          .withResult(_run(id: LevelResult.endlessId, stars: 0, score: 900, runId: 'e1'))
          .unlockAchievements(['splat_1'], DateTime.utc(2026, 11, 16));
      final json = progress.toJson();
      expect(json['schemaVersion'], 3);
      expect(PlayerProgress.fromJson(json).toJson(), json);
    });
  });

  test('repository unlockAchievements persists', () async {
    final repository = InMemoryProgressRepository();
    final progress = await repository.unlockAchievements(['first_win']);
    expect(progress.hasAchievement('first_win'), isTrue);
    expect((await repository.load()).hasAchievement('first_win'), isTrue);
  });
}
