import 'dart:math';

import '../achievements/achievements.dart';
import '../economy/catalog.dart';
import '../economy/rewards.dart';
import '../levels/level_definition.dart';
import 'level_result.dart';
import 'lifetime_stats.dart';

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

/// Why a shop action was refused.
enum ShopError { unknownItem, notEnoughCoins, maxedOut, alreadyOwned, notOwned }

class ShopException implements Exception {
  const ShopException(this.error);

  final ShopError error;

  @override
  String toString() => 'ShopException(${error.name})';
}

/// Everything the player has achieved and owns. Immutable; every change
/// returns an updated copy. Serialised with [schemaVersion] so stored or
/// synced data can be migrated.
///
/// Coin changes go through named operations ([withResult], [buyUpgrade],
/// [buyCosmetic], [withCoins]) so a backend can later replay or validate
/// them instead of trusting a client-side balance.
class PlayerProgress {
  const PlayerProgress({
    this.levels = const {},
    this.endlessBest = 0,
    this.coins = 0,
    this.lifetimeCoins = 0,
    this.upgrades = const {},
    this.owned = const {},
    this.equipped = const {},
    this.stats = const LifetimeStats(),
    this.achievements = const {},
    this.endlessTop = const [],
    this.removeAds = false,
  });

  /// 1: levels and endless best. 2: adds coins, upgrades and cosmetics.
  /// 3: adds lifetime stats, achievements and the Endless top list.
  /// 4: adds [removeAds].
  static const int schemaVersion = 4;

  /// How many Endless runs the personal top list keeps.
  static const int endlessTopSize = 10;

  final Map<String, LevelRecord> levels;
  final int endlessBest;
  final int coins;

  /// Every coin ever earned, for achievements and analytics.
  final int lifetimeCoins;

  /// Upgrade id to tier bought.
  final Map<String, int> upgrades;

  /// Ids of bought cosmetics. Free cosmetics are always owned.
  final Set<String> owned;

  /// Cosmetic slot name to equipped cosmetic id.
  final Map<String, String> equipped;

  final LifetimeStats stats;

  /// Unlocked achievement ids and when they were unlocked.
  final Map<String, DateTime> achievements;

  /// Best Endless runs, highest score first.
  final List<EndlessRun> endlessTop;

  /// Player bought Remove Ads (or starter pack that includes it later).
  final bool removeAds;

  bool hasAchievement(String id) => achievements.containsKey(id);

  /// 1-based place of the run with [runId] in [endlessTop], or null.
  int? endlessRankOf(String runId) {
    final index = endlessTop.indexWhere((r) => r.runId == runId);
    return index < 0 ? null : index + 1;
  }

  LevelRecord recordFor(String levelId) =>
      levels[levelId] ?? const LevelRecord();

  int get totalStars =>
      levels.values.fold(0, (sum, record) => sum + record.bestStars);

  int starsIn(WorldDefinition world) =>
      world.levelIds.fold(0, (sum, id) => sum + recordFor(id).bestStars);

  bool isWorldComplete(WorldDefinition world) =>
      world.levelIds.isNotEmpty &&
      world.levelIds.every((id) => recordFor(id).completed);

  int upgradeTier(UpgradeId id) => upgrades[id.id] ?? 0;

  bool owns(String cosmeticId) {
    final item = Catalog.cosmetic(cosmeticId);
    return item != null && (item.isFree || owned.contains(cosmeticId));
  }

  String equippedIn(CosmeticSlot slot) {
    final id = equipped[slot.name];
    return id != null && owns(id) ? id : Catalog.defaultFor(slot).id;
  }

  /// What the next run is played with.
  Loadout get loadout => Loadout(
        upgrades: {
          for (final id in UpgradeId.values)
            if (upgradeTier(id) > 0) id: upgradeTier(id),
        },
        plumage: equippedIn(CosmeticSlot.plumage),
        poop: equippedIn(CosmeticSlot.poop),
      );

  PlayerProgress _copy({
    Map<String, LevelRecord>? levels,
    int? endlessBest,
    int? coins,
    int? lifetimeCoins,
    Map<String, int>? upgrades,
    Set<String>? owned,
    Map<String, String>? equipped,
    LifetimeStats? stats,
    Map<String, DateTime>? achievements,
    List<EndlessRun>? endlessTop,
    bool? removeAds,
  }) =>
      PlayerProgress(
        levels: levels ?? this.levels,
        endlessBest: endlessBest ?? this.endlessBest,
        coins: coins ?? this.coins,
        lifetimeCoins: lifetimeCoins ?? this.lifetimeCoins,
        upgrades: upgrades ?? this.upgrades,
        owned: owned ?? this.owned,
        equipped: equipped ?? this.equipped,
        stats: stats ?? this.stats,
        achievements: achievements ?? this.achievements,
        endlessTop: endlessTop ?? this.endlessTop,
        removeAds: removeAds ?? this.removeAds,
      );

  PlayerProgress withRemoveAds() => _copy(removeAds: true);

  /// Grants a cosmetic without charging coins (IAP starter pack, etc.).
  PlayerProgress grantCosmetic(String cosmeticId) {
    final item = Catalog.cosmetic(cosmeticId);
    if (item == null) return this;
    if (owns(cosmeticId)) return this;
    return _copy(owned: {...owned, cosmeticId}).equip(cosmeticId);
  }

  /// Records a finished run and pays its [RewardRules] reward.
  PlayerProgress withResult(LevelResult result) {
    final reward = RewardRules.forResult(result, this);
    final paid = withCoins(reward.total)._copy(stats: stats.add(result));
    if (result.isEndless) {
      final top = [...endlessTop, EndlessRun.from(result)]
        ..sort((a, b) => b.score.compareTo(a.score));
      return paid._copy(
        endlessBest: max(endlessBest, result.score),
        endlessTop: top.take(endlessTopSize).toList(),
      );
    }
    return paid._copy(levels: {
      ...levels,
      result.levelId: recordFor(result.levelId).merge(result),
    });
  }

  /// Marks achievements as unlocked and pays their coin rewards. Unknown or
  /// already unlocked ids are ignored.
  PlayerProgress unlockAchievements(Iterable<String> ids, DateTime at) {
    final fresh = ids
        .where((id) => !hasAchievement(id) && Achievements.byId(id) != null)
        .toSet();
    if (fresh.isEmpty) return this;
    final coins =
        fresh.fold(0, (sum, id) => sum + Achievements.byId(id)!.coins);
    return withCoins(coins)._copy(achievements: {
      ...achievements,
      for (final id in fresh) id: at.toUtc(),
    });
  }

  /// Adds (or, if negative, removes) coins. Earnings count toward
  /// [lifetimeCoins].
  PlayerProgress withCoins(int amount) => _copy(
        coins: max(0, coins + amount),
        lifetimeCoins: lifetimeCoins + max(0, amount),
      );

  /// Buys the next tier of an upgrade.
  PlayerProgress buyUpgrade(UpgradeId id) {
    final tier = upgradeTier(id);
    final cost = Catalog.upgrade(id).nextCost(tier);
    if (cost == null) throw const ShopException(ShopError.maxedOut);
    if (coins < cost) throw const ShopException(ShopError.notEnoughCoins);
    return _copy(
      coins: coins - cost,
      upgrades: {...upgrades, id.id: tier + 1},
    );
  }

  /// Buys a cosmetic and equips it.
  PlayerProgress buyCosmetic(String cosmeticId) {
    final item = Catalog.cosmetic(cosmeticId);
    if (item == null) throw const ShopException(ShopError.unknownItem);
    if (owns(cosmeticId)) throw const ShopException(ShopError.alreadyOwned);
    if (coins < item.price) {
      throw const ShopException(ShopError.notEnoughCoins);
    }
    return _copy(
      coins: coins - item.price,
      owned: {...owned, cosmeticId},
    ).equip(cosmeticId);
  }

  PlayerProgress equip(String cosmeticId) {
    final item = Catalog.cosmetic(cosmeticId);
    if (item == null) throw const ShopException(ShopError.unknownItem);
    if (!owns(cosmeticId)) throw const ShopException(ShopError.notOwned);
    return _copy(equipped: {...equipped, item.slot.name: cosmeticId});
  }

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as int? ?? 1;
    if (version > schemaVersion) {
      throw FormatException(
          'Progress schema $version is newer than $schemaVersion');
    }
    // Older versions simply lack the newer fields; their defaults are the
    // correct migration.
    return PlayerProgress(
      levels: {
        for (final e in (json['levels'] as Map<String, dynamic>? ?? {}).entries)
          e.key: LevelRecord.fromJson(e.value as Map<String, dynamic>),
      },
      endlessBest: json['endlessBest'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      lifetimeCoins: json['lifetimeCoins'] as int? ?? 0,
      upgrades: {
        for (final e
            in (json['upgrades'] as Map<String, dynamic>? ?? {}).entries)
          e.key: e.value as int,
      },
      owned: {
        for (final id in json['owned'] as List<dynamic>? ?? const [])
          id as String,
      },
      equipped: {
        for (final e
            in (json['equipped'] as Map<String, dynamic>? ?? {}).entries)
          e.key: e.value as String,
      },
      stats: LifetimeStats.fromJson(
          json['stats'] as Map<String, dynamic>? ?? const {}),
      achievements: {
        for (final e
            in (json['achievements'] as Map<String, dynamic>? ?? {}).entries)
          e.key: DateTime.parse(e.value as String),
      },
      endlessTop: [
        for (final run in json['endlessTop'] as List<dynamic>? ?? const [])
          EndlessRun.fromJson(run as Map<String, dynamic>),
      ],
      removeAds: json['removeAds'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'levels': {for (final e in levels.entries) e.key: e.value.toJson()},
        'endlessBest': endlessBest,
        'coins': coins,
        'lifetimeCoins': lifetimeCoins,
        'upgrades': upgrades,
        'owned': owned.toList()..sort(),
        'equipped': equipped,
        'stats': stats.toJson(),
        'achievements': {
          for (final e in achievements.entries)
            e.key: e.value.toUtc().toIso8601String(),
        },
        'endlessTop': [for (final run in endlessTop) run.toJson()],
        'removeAds': removeAds,
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
