import '../economy/catalog.dart';
import '../levels/level_definition.dart';
import '../progress/level_result.dart';
import '../progress/player_progress.dart';

enum AchievementCategory {
  splatting('Splatting'),
  skill('Skill'),
  progress('Progress'),
  endless('Endless'),
  collection('Collection');

  const AchievementCategory(this.label);

  final String label;
}

/// What an achievement is checked against: the player's progress after the
/// latest action, the run that was just played (if any), and the worlds.
class AchievementContext {
  const AchievementContext({
    required this.progress,
    required this.worlds,
    this.run,
  });

  final PlayerProgress progress;
  final List<WorldDefinition> worlds;
  final LevelResult? run;

  WorldDefinition? world(String id) {
    for (final w in worlds) {
      if (w.id == id) return w;
    }
    return null;
  }
}

/// A one-time task with a coin reward.
///
/// Either a counter ([target] and [value]: unlocked when the value reaches
/// the target, with a progress bar) or a single-run feat ([feat]: checked
/// against the run just played).
class AchievementDefinition {
  const AchievementDefinition.counter({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.coins,
    required int this.target,
    required int Function(AchievementContext) this.value,
  }) : feat = null;

  const AchievementDefinition.feat({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.coins,
    required bool Function(LevelResult run) this.feat,
  })  : target = null,
        value = null;

  /// Stable id, stored in progress and checked by the backend. Never rename.
  final String id;
  final String name;
  final String description;
  final AchievementCategory category;
  final int coins;

  final int? target;
  final int Function(AchievementContext)? value;
  final bool Function(LevelResult run)? feat;

  bool get isCounter => target != null;

  bool isEarned(AchievementContext context) {
    if (isCounter) return value!(context) >= target!;
    final run = context.run;
    return run != null && feat!(run);
  }

  /// Progress toward a counter achievement, 0 to 1; null for feats.
  double? progressIn(AchievementContext context) =>
      isCounter ? (value!(context) / target!).clamp(0.0, 1.0) : null;
}

bool _won(LevelResult r) => !r.isEndless && r.outcome.isWin;

/// Every achievement in the game.
abstract final class Achievements {
  static final List<AchievementDefinition> all = [
    // ─── Splatting ──────────────────────────────────────────────────────
    for (final (id, name, target, coins) in const [
      ('splat_1', 'First Splat', 1, 10),
      ('splat_100', 'Traffic Menace', 100, 50),
      ('splat_1000', 'Rush Hour Terror', 1000, 200),
      ('splat_10000', 'Road Legend', 10000, 1000),
    ])
      AchievementDefinition.counter(
        id: id,
        name: name,
        description: target == 1
            ? 'Splat your first car.'
            : 'Splat $target cars in total.',
        category: AchievementCategory.splatting,
        coins: coins,
        target: target,
        value: (c) => c.progress.stats.carsSplatted,
      ),
    AchievementDefinition.counter(
      id: 'sports_25',
      name: 'Speed Trap',
      description: 'Splat 25 sports cars.',
      category: AchievementCategory.splatting,
      coins: 75,
      target: 25,
      value: (c) => c.progress.stats.splatsOf('sportsCar'),
    ),
    AchievementDefinition.counter(
      id: 'poops_5000',
      name: 'Bottomless',
      description: 'Drop 5,000 poops.',
      category: AchievementCategory.splatting,
      coins: 150,
      target: 5000,
      value: (c) => c.progress.stats.poopsDropped,
    ),
    AchievementDefinition.feat(
      id: 'multi_3',
      name: 'Triple Splat',
      description: 'Splat 3 cars with one big poop.',
      category: AchievementCategory.splatting,
      coins: 100,
      feat: (r) => r.bestMultiSplat >= 3,
    ),

    // ─── Skill ──────────────────────────────────────────────────────────
    for (final (id, name, combo, coins) in const [
      ('combo_5', 'Combo Starter', 5, 25),
      ('combo_10', 'Combo King', 10, 100),
      ('combo_20', 'Unstoppable', 20, 300),
    ])
      AchievementDefinition.feat(
        id: id,
        name: name,
        description: 'Reach a x$combo combo.',
        category: AchievementCategory.skill,
        coins: coins,
        feat: (r) => r.bestCombo >= combo,
      ),
    AchievementDefinition.feat(
      id: 'zen_bird',
      name: 'Zen Bird',
      description: 'Win a level without rage going above 20%.',
      category: AchievementCategory.skill,
      coins: 100,
      feat: (r) => _won(r) && r.maxRage <= 0.2 + 1e-9,
    ),
    AchievementDefinition.feat(
      id: 'sharpshooter',
      name: 'Sharpshooter',
      description: 'Win a level without a single poop missing (10+ poops).',
      category: AchievementCategory.skill,
      coins: 150,
      feat: (r) => _won(r) && r.poopsDropped >= 10 && r.poopsMissed == 0,
    ),
    AchievementDefinition.feat(
      id: 'no_escape',
      name: 'No Car Left Behind',
      description: 'Win a level without letting a clean car escape.',
      category: AchievementCategory.skill,
      coins: 100,
      feat: (r) => _won(r) && r.escapes == 0,
    ),
    AchievementDefinition.feat(
      id: 'hungry_bird',
      name: 'Hungry Bird',
      description: 'Eat 10 snacks in one run.',
      category: AchievementCategory.skill,
      coins: 50,
      feat: (r) => r.foodEaten >= 10,
    ),

    // ─── Progress ───────────────────────────────────────────────────────
    AchievementDefinition.feat(
      id: 'first_win',
      name: 'Off the Nest',
      description: 'Complete your first level.',
      category: AchievementCategory.progress,
      coins: 10,
      feat: _won,
    ),
    AchievementDefinition.feat(
      id: 'three_stars',
      name: 'Perfectionist',
      description: 'Get 3 stars on a level.',
      category: AchievementCategory.progress,
      coins: 50,
      feat: (r) => !r.isEndless && r.stars >= 3,
    ),
    AchievementDefinition.counter(
      id: 'boss_1',
      name: 'Boss Slayer',
      description: 'Defeat a boss.',
      category: AchievementCategory.progress,
      coins: 100,
      target: 1,
      value: (c) => c.progress.stats.bossesDefeated,
    ),
    AchievementDefinition.counter(
      id: 'stars_25',
      name: 'Star Collector',
      description: 'Earn 25 stars.',
      category: AchievementCategory.progress,
      coins: 150,
      target: 25,
      value: (c) => c.progress.totalStars,
    ),
    for (final (world, name) in const [
      ('w1', 'Suburbs'),
      ('w2', 'Downtown'),
      ('w3', 'Highway'),
      ('w4', 'Beach Boardwalk'),
      ('w5', 'Night City'),
    ]) ...[
      AchievementDefinition.counter(
        id: '${world}_complete',
        name: '$name Survivor',
        description: 'Complete every level in $name.',
        category: AchievementCategory.progress,
        coins: 200,
        target: 1,
        value: (c) {
          final w = c.world(world);
          return w != null && c.progress.isWorldComplete(w) ? 1 : 0;
        },
      ),
      AchievementDefinition.counter(
        id: '${world}_perfect',
        name: '$name Legend',
        description: 'Get all 3 stars on every level in $name.',
        category: AchievementCategory.progress,
        coins: 400,
        target: 1,
        value: (c) {
          final w = c.world(world);
          return w != null &&
                  w.levelIds.isNotEmpty &&
                  c.progress.starsIn(w) == w.levelIds.length * 3
              ? 1
              : 0;
        },
      ),
    ],
    AchievementDefinition.counter(
      id: 'runs_100',
      name: 'Frequent Flyer',
      description: 'Play 100 runs.',
      category: AchievementCategory.progress,
      coins: 150,
      target: 100,
      value: (c) => c.progress.stats.runs,
    ),

    // ─── Endless ────────────────────────────────────────────────────────
    for (final (id, name, score, coins) in const [
      ('endless_1000', 'Endless Rookie', 1000, 25),
      ('endless_5000', 'Endless Pro', 5000, 100),
      ('endless_15000', 'Endless Legend', 15000, 300),
    ])
      AchievementDefinition.counter(
        id: id,
        name: name,
        description: 'Score $score in Endless.',
        category: AchievementCategory.endless,
        coins: coins,
        target: score,
        value: (c) => c.progress.endlessBest,
      ),
    AchievementDefinition.feat(
      id: 'marathon',
      name: 'Marathon Bird',
      description: 'Survive 3 minutes in Endless.',
      category: AchievementCategory.endless,
      coins: 150,
      feat: (r) => r.isEndless && r.durationSeconds >= 180,
    ),
    AchievementDefinition.feat(
      id: 'endless_boss',
      name: 'Car Wash Crasher',
      description: 'Defeat the Car Wash Truck in Endless.',
      category: AchievementCategory.endless,
      coins: 150,
      feat: (r) => r.isEndless && r.bossesDefeated > 0,
    ),

    // ─── Collection ─────────────────────────────────────────────────────
    AchievementDefinition.counter(
      id: 'first_upgrade',
      name: 'Upgrade!',
      description: 'Buy an upgrade.',
      category: AchievementCategory.collection,
      coins: 25,
      target: 1,
      value: (c) => c.progress.upgrades.values.fold(0, (a, b) => a + b),
    ),
    AchievementDefinition.counter(
      id: 'maxed_upgrade',
      name: 'Fully Loaded',
      description: 'Max out an upgrade.',
      category: AchievementCategory.collection,
      coins: 100,
      target: 1,
      value: (c) => Catalog.upgrades
          .where((u) => c.progress.upgradeTier(u.id) >= u.maxTier)
          .length,
    ),
    AchievementDefinition.counter(
      id: 'fashion',
      name: 'Fashion Bird',
      description: 'Buy a cosmetic.',
      category: AchievementCategory.collection,
      coins: 25,
      target: 1,
      value: (c) => c.progress.owned.length,
    ),
    AchievementDefinition.counter(
      id: 'coins_5000',
      name: 'Nest Egg',
      description: 'Earn 5,000 coins in total.',
      category: AchievementCategory.collection,
      coins: 250,
      target: 5000,
      value: (c) => c.progress.lifetimeCoins,
    ),
  ];

  static final Map<String, AchievementDefinition> _byId = {
    for (final a in all) a.id: a,
  };

  static AchievementDefinition? byId(String id) => _byId[id];

  /// Achievements earned in [context] that aren't unlocked yet.
  static List<AchievementDefinition> newlyEarned(AchievementContext context) =>
      [
        for (final a in all)
          if (!context.progress.hasAchievement(a.id) && a.isEarned(context)) a,
      ];
}
