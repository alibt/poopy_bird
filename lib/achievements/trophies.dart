import '../levels/level_definition.dart';
import '../progress/player_progress.dart';
import 'achievements.dart';

enum TrophyTier { none, bronze, silver, gold }

/// A trophy shown in the Trophy Room. Trophies are derived from progress,
/// never stored, so they can't drift out of sync with it.
class Trophy {
  const Trophy({
    required this.id,
    required this.name,
    required this.tier,
    required this.requirements,
  });

  final String id;
  final String name;
  final TrophyTier tier;

  /// What earns each tier: bronze, silver, gold.
  final List<String> requirements;

  /// What to do for the next tier, or null at gold.
  String? get nextGoal =>
      tier == TrophyTier.gold ? null : requirements[tier.index];
}

abstract final class Trophies {
  /// Endless score needed for bronze, silver and gold.
  static const List<int> endlessScores = [5000, 15000, 30000];

  static List<Trophy> all(
      PlayerProgress progress, List<WorldDefinition> worlds) {
    final playable = worlds.where((w) => !w.comingSoon).toList();
    return [
      for (final world in playable) _world(progress, world),
      _completion(progress, playable),
      _endless(progress),
      _collector(progress),
    ];
  }

  /// Bronze: complete the world. Silver: two thirds of its stars. Gold: all.
  static Trophy _world(PlayerProgress progress, WorldDefinition world) {
    final maxStars = world.levelIds.length * 3;
    final stars = progress.starsIn(world);
    final tier = !progress.isWorldComplete(world)
        ? TrophyTier.none
        : stars == maxStars
            ? TrophyTier.gold
            : stars * 3 >= maxStars * 2
                ? TrophyTier.silver
                : TrophyTier.bronze;
    return Trophy(
      id: 'world_${world.id}',
      name: '${world.name} Cup',
      tier: tier,
      requirements: [
        'Complete every level in ${world.name}',
        'Earn ${(maxStars * 2 / 3).ceil()} stars in ${world.name}',
        'Earn all $maxStars stars in ${world.name}',
      ],
    );
  }

  /// Every playable world's cup at bronze, silver, then gold.
  static Trophy _completion(
      PlayerProgress progress, List<WorldDefinition> worlds) {
    final cups = [for (final w in worlds) _world(progress, w).tier];
    final lowest = cups.isEmpty
        ? TrophyTier.none
        : cups.reduce((a, b) => a.index < b.index ? a : b);
    return Trophy(
      id: 'completion',
      name: 'Grand Tour',
      tier: lowest,
      requirements: const [
        'Win a bronze cup in every world',
        'Win a silver cup in every world',
        'Win a gold cup in every world',
      ],
    );
  }

  static Trophy _endless(PlayerProgress progress) {
    var tier = TrophyTier.none;
    for (var i = 0; i < endlessScores.length; i++) {
      if (progress.endlessBest >= endlessScores[i]) {
        tier = TrophyTier.values[i + 1];
      }
    }
    return Trophy(
      id: 'endless',
      name: 'Endless Medal',
      tier: tier,
      requirements: [
        for (final score in endlessScores) 'Score $score in Endless',
      ],
    );
  }

  /// A third, two thirds, or all achievements.
  static Trophy _collector(PlayerProgress progress) {
    final total = Achievements.all.length;
    final have =
        Achievements.all.where((a) => progress.hasAchievement(a.id)).length;
    final thresholds = [(total / 3).ceil(), (total * 2 / 3).ceil(), total];
    var tier = TrophyTier.none;
    for (var i = 0; i < 3; i++) {
      if (have >= thresholds[i]) tier = TrophyTier.values[i + 1];
    }
    return Trophy(
      id: 'collector',
      name: 'Achievement Hunter',
      tier: tier,
      requirements: [
        for (final n in thresholds) 'Unlock $n achievements',
      ],
    );
  }
}
