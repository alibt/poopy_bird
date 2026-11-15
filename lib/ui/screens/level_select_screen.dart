import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../widgets.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key, required this.worldId});

  final String worldId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final world = controller.worlds.firstWhere((w) => w.id == worldId);
    final rules = controller.rules;

    return SkyBackground(
      child: Column(
        children: [
          ScreenHeader(
            title: world.name,
            trailing: StarCount(
              earned: controller.progress.starsIn(world),
              total: world.levelIds.length * 3,
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < world.levelIds.length; i++)
                      _LevelTile(
                        label: '${i + 1}',
                        isBoss: i == world.levelIds.length - 1,
                        unlocked: rules.isLevelUnlocked(world, i),
                        stars: controller.progress
                            .recordFor(world.levelIds[i])
                            .bestStars,
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              GameScreen(levelId: world.levelIds[i]),
                        )),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.label,
    required this.isBoss,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final String label;
  final bool isBoss;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget face;
    if (!unlocked) {
      face = const Icon(Icons.lock_rounded, color: brandBrown, size: 30);
    } else if (isBoss) {
      face =
          const Icon(Icons.local_car_wash_rounded, color: brandBrown, size: 34);
    } else {
      face = Text(
        label,
        style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.w900, color: brandBrown),
      );
    }

    return SizedBox(
      width: isBoss ? 110 : 84,
      height: 92,
      child: Material(
        color: !unlocked
            ? Colors.white54
            : isBoss
                ? const Color(0xFFFFE082)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: brandBrown, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: unlocked ? onTap : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              face,
              const SizedBox(height: 6),
              if (unlocked) StarRow(stars: stars, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
