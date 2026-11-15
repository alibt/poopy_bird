import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/economy/catalog.dart';
import 'package:poopy_bird/economy/rewards.dart';
import 'package:poopy_bird/progress/level_result.dart';
import 'package:poopy_bird/progress/player_progress.dart';
import 'package:poopy_bird/progress/progress_repository.dart';
import 'package:poopy_bird/storage/key_value_store.dart';

LevelResult _run(
  String id, {
  int stars = 1,
  int score = 1500,
  bool isBoss = false,
}) =>
    LevelResult(
      levelId: id,
      levelVersion: 1,
      outcome: stars > 0 ? RunOutcome.won : RunOutcome.crashed,
      stars: stars,
      score: score,
      carsSplatted: 5,
      bestCombo: 2,
      escapes: 0,
      durationSeconds: 40,
      finishedAt: DateTime.utc(2026, 11, 16),
      isBoss: isBoss,
    );

void main() {
  group('RewardRules', () {
    test('pays for score, the win, and only newly earned stars', () {
      const before = PlayerProgress();
      final first = RewardRules.forResult(_run('a', stars: 2), before);
      expect(first.scoreCoins, 15);
      expect(first.winBonus, RewardRules.winBonus);
      expect(first.newStarCoins, 2 * RewardRules.coinsPerNewStar);

      final after = before.withResult(_run('a', stars: 2));
      expect(after.coins, first.total);
      final replay = RewardRules.forResult(_run('a', stars: 3), after);
      expect(replay.newStarCoins, RewardRules.coinsPerNewStar);
      final worse = RewardRules.forResult(_run('a', stars: 1), after);
      expect(worse.newStarCoins, 0);
    });

    test('a loss pays only score coins, and score coins are capped', () {
      final loss = RewardRules.forResult(
          _run('a', stars: 0, score: 99999), const PlayerProgress());
      expect(loss.total, RewardRules.maxScoreCoins);
    });

    test('a boss pays its first-clear bonus once', () {
      final boss = _run('boss', isBoss: true);
      final first = RewardRules.forResult(boss, const PlayerProgress());
      expect(first.firstClearBonus, RewardRules.bossFirstClearBonus);
      final again =
          RewardRules.forResult(boss, const PlayerProgress().withResult(boss));
      expect(again.firstClearBonus, 0);
    });

    test('endless pays by score', () {
      final reward = RewardRules.forResult(
          _run(LevelResult.endlessId, stars: 0, score: 8000),
          const PlayerProgress());
      expect(reward.total, 100);
    });
  });

  group('shop', () {
    const rich = PlayerProgress(coins: 10000);

    test('upgrades cost their tier price and stop at max', () {
      var progress = rich;
      final costs = Catalog.upgrade(UpgradeId.belly).costs;
      for (final cost in costs) {
        final before = progress.coins;
        progress = progress.buyUpgrade(UpgradeId.belly);
        expect(before - progress.coins, cost);
      }
      expect(progress.upgradeTier(UpgradeId.belly), costs.length);
      expect(
          () => progress.buyUpgrade(UpgradeId.belly),
          throwsA(isA<ShopException>()
              .having((e) => e.error, 'error', ShopError.maxedOut)));
      expect(progress.loadout.bellyCapacity, 6 + costs.length);
    });

    test('cannot buy without enough coins', () {
      expect(
          () => const PlayerProgress(coins: 10).buyUpgrade(UpgradeId.calm),
          throwsA(isA<ShopException>()
              .having((e) => e.error, 'error', ShopError.notEnoughCoins)));
      expect(() => const PlayerProgress().buyCosmetic('poop_gold'),
          throwsA(isA<ShopException>()));
    });

    test('buying a cosmetic equips it; free ones are always owned', () {
      final progress = rich.buyCosmetic('poop_slime');
      expect(progress.equippedIn(CosmeticSlot.poop), 'poop_slime');
      expect(progress.loadout.poopColor, const Color(0xFF7CB342));
      final back = progress.equip('poop_classic');
      expect(back.equippedIn(CosmeticSlot.poop), 'poop_classic');
      expect(
          () => back.buyCosmetic('poop_slime'), throwsA(isA<ShopException>()));
      expect(() => rich.equip('plumage_royal'), throwsA(isA<ShopException>()));
    });

    test('every upgrade label renders for every tier', () {
      for (final upgrade in Catalog.upgrades) {
        for (var tier = 0; tier <= upgrade.maxTier; tier++) {
          expect(upgrade.effectLabel(tier), isNotEmpty);
        }
      }
      final ids = Catalog.cosmetics.map((c) => c.id).toSet();
      expect(ids, hasLength(Catalog.cosmetics.length), reason: 'unique ids');
    });
  });

  group('PlayerProgress v2', () {
    test('JSON round trip keeps the economy', () {
      final progress = const PlayerProgress(coins: 5000)
          .withResult(_run('a', stars: 3))
          .buyUpgrade(UpgradeId.combo)
          .buyCosmetic('plumage_mint');
      final json =
          jsonDecode(jsonEncode(progress.toJson())) as Map<String, dynamic>;
      expect(PlayerProgress.fromJson(json).toJson(), progress.toJson());
    });

    test('migrates schema 1 data', () {
      final progress = PlayerProgress.fromJson({
        'schemaVersion': 1,
        'levels': {
          'a': {'bestStars': 2, 'bestScore': 900, 'plays': 3}
        },
        'endlessBest': 50,
      });
      expect(progress.recordFor('a').bestStars, 2);
      expect(progress.coins, 0);
      expect(progress.equippedIn(CosmeticSlot.plumage), 'plumage_classic');
    });
  });

  group('LocalProgressRepository', () {
    test('progress survives a restart', () async {
      final store = MemoryKeyValueStore();
      final first = LocalProgressRepository(store);
      final recorded = await first.record(_run('a', stars: 3));
      expect(recorded.reward.total, greaterThan(0));
      await first.grantCoins(500, reason: 'test');
      await first.buyUpgrade(UpgradeId.belly);

      final reopened = LocalProgressRepository(store);
      final progress = await reopened.load();
      expect(progress.recordFor('a').bestStars, 3);
      expect(progress.upgradeTier(UpgradeId.belly), 1);
      expect(progress.coins, recorded.reward.total + 500 - 150);
      expect(
        (await reopened.pendingActions()).map((a) => a['action']),
        ['run', 'grantCoins', 'buyUpgrade'],
      );
    });

    test('corrupt data starts fresh but is kept aside', () async {
      final store = MemoryKeyValueStore(
          {LocalProgressRepository.progressKey: '{not json'});
      final progress = await LocalProgressRepository(store).load();
      expect(progress.coins, 0);
      expect(store.values[LocalProgressRepository.corruptKey], '{not json');
    });

    test('two quick purchases cannot spend the same coins', () async {
      final repository =
          InMemoryProgressRepository(const PlayerProgress(coins: 150));
      final results = await Future.wait([
        repository
            .buyUpgrade(UpgradeId.belly)
            .then((_) => true, onError: (_) => false),
        repository
            .buyUpgrade(UpgradeId.digestion)
            .then((_) => true, onError: (_) => false),
      ]);
      expect(results, [true, false]);
      expect((await repository.load()).coins, 0);
    });

    test('a refused purchase changes nothing', () async {
      final store = MemoryKeyValueStore();
      final repository = LocalProgressRepository(store);
      await expectLater(
          repository.buyUpgrade(UpgradeId.calm), throwsA(isA<ShopException>()));
      expect(store.values, isEmpty);
    });
  });
}
