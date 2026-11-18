import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../widgets.dart';
import 'achievements_screen.dart';
import 'game_screen.dart';
import 'shop_screen.dart';
import 'trophy_room_screen.dart';
import 'world_map_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final endlessUnlocked = controller.rules.isEndlessUnlocked;
    final firstWorld =
        controller.worlds.isEmpty ? null : controller.worlds.first.name;

    return SkyBackground(
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 20,
            child: GestureDetector(
              // Debug builds: long-press the coins for 1000 more.
              onLongPress:
                  kDebugMode ? () => controller.grantDebugCoins(1000) : null,
              child: CoinCount(coins: controller.progress.coins, size: 26),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/bird_01.png', height: 170),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        // Debug builds: long-press the title to unlock everything.
                        onLongPress: kDebugMode
                            ? () {
                                controller.toggleUnlockAll();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(controller.unlockAll
                                      ? 'Debug: everything unlocked'
                                      : 'Debug: normal unlocks'),
                                ));
                              }
                            : null,
                        child: const Text(
                          'POOPY BIRD',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: brandBrown,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: Colors.white, blurRadius: 8)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const WorldMapScreen()),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: endlessUnlocked
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const GameScreen()),
                                )
                            : null,
                        icon: Icon(endlessUnlocked
                            ? Icons.all_inclusive_rounded
                            : Icons.lock_rounded),
                        label: const Text('Endless'),
                      ),
                      if (!endlessUnlocked && firstWorld != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Complete $firstWorld to unlock',
                            style: const TextStyle(color: brandBrown),
                          ),
                        ),
                      if (endlessUnlocked &&
                          controller.progress.endlessBest > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Best: ${controller.progress.endlessBest}',
                            style: const TextStyle(
                                color: brandBrown, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ShopScreen()),
                        ),
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Shop'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen()),
                            ),
                            icon: const Icon(Icons.emoji_events_outlined),
                            label: const Text('Achievements'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const TrophyRoomScreen()),
                            ),
                            icon: const Icon(Icons.military_tech_rounded),
                            label: const Text('Trophies'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
