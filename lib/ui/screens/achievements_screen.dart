import 'package:flutter/material.dart';

import '../../achievements/achievements.dart';
import '../../app/app_scope.dart';
import '../../progress/player_progress.dart';
import '../widgets.dart';

/// Lists every achievement, grouped by category, with progress bars for
/// counters and a check for feats already unlocked.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final progress = controller.progress;
    final unlocked =
        Achievements.all.where((a) => progress.hasAchievement(a.id)).length;
    final eval = AchievementContext(
      progress: progress,
      worlds: controller.worlds,
    );

    return SkyBackground(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Achievements',
            trailing: Text(
              '$unlocked / ${Achievements.all.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: brandBrown,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                for (final category in AchievementCategory.values) ...[
                  _CategoryHeader(category: category),
                  for (final a
                      in Achievements.all.where((a) => a.category == category))
                    _AchievementTile(
                      achievement: a,
                      progress: progress,
                      eval: eval,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final AchievementCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        category.label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: brandBrown,
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.progress,
    required this.eval,
  });

  final AchievementDefinition achievement;
  final PlayerProgress progress;
  final AchievementContext eval;

  @override
  Widget build(BuildContext context) {
    final earned = progress.hasAchievement(achievement.id);
    final bar = achievement.progressIn(eval);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: earned ? 0.95 : 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned ? brandYellow : brandBrown.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            earned ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: earned ? brandYellow : brandBrown.withValues(alpha: 0.45),
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: brandBrown.withValues(alpha: earned ? 1 : 0.7),
                    fontSize: 15,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: brandBrown.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                if (bar != null && !earned) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bar,
                      minHeight: 6,
                      backgroundColor: brandBrown.withValues(alpha: 0.12),
                      color: brandYellow,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${achievement.value!(eval)} / ${achievement.target}',
                    style: TextStyle(
                      fontSize: 11,
                      color: brandBrown.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded,
                  color: coinGold, size: 16),
              Text(
                ' ${achievement.coins}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: brandBrown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
