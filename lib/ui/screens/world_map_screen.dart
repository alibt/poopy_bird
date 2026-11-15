import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../levels/level_definition.dart';
import '../widgets.dart';
import 'level_select_screen.dart';

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final rules = controller.rules;
    final playableLevels =
        controller.worlds.fold(0, (sum, w) => sum + w.levelIds.length);

    return SkyBackground(
      child: Column(
        children: [
          ScreenHeader(
            title: 'World Map',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarCount(
                  earned: controller.progress.totalStars,
                  total: playableLevels * 3,
                ),
                const SizedBox(width: 16),
                CoinCount(coins: controller.progress.coins),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: controller.worlds.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final world = controller.worlds[i];
                return _WorldCard(
                  number: i + 1,
                  world: world,
                  unlocked: rules.isWorldUnlocked(world),
                  stars: controller.progress.starsIn(world),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.number,
    required this.world,
    required this.unlocked,
    required this.stars,
  });

  final int number;
  final WorldDefinition world;
  final bool unlocked;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final status = world.comingSoon
        ? 'Coming soon'
        : unlocked
            ? null
            : 'Complete the previous world';

    return SizedBox(
      width: 190,
      child: Material(
        color: unlocked ? Colors.white : Colors.white54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: brandBrown, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: unlocked
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => LevelSelectScreen(worldId: world.id),
                  ))
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'World $number',
                  style: const TextStyle(
                      color: brandBrown, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  world.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: brandBrown,
                  ),
                ),
                const SizedBox(height: 12),
                if (status == null)
                  StarCount(earned: stars, total: world.levelIds.length * 3)
                else ...[
                  const Icon(Icons.lock_rounded, color: brandBrown, size: 32),
                  const SizedBox(height: 4),
                  Text(status, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
