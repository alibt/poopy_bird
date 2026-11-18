import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../audio/game_audio.dart';
import '../widgets.dart';
import 'achievements_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'trophy_room_screen.dart';
import 'world_map_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).audio.playMusic(GameAudio.menuMusic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final endlessUnlocked = controller.rules.isEndlessUnlocked;
    final firstWorld =
        controller.worlds.isEmpty ? null : controller.worlds.first.name;
    final showTutorialCta = !controller.settings.seenTutorial;

    return SkyBackground(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.flip(
                    flipX: true,
                    child: Image.asset('assets/images/bird_01.png', height: 170),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
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
                      if (showTutorialCta) ...[
                        FilledButton.icon(
                          onPressed: () {
                            controller.audio.sfx('ui_tap.wav');
                            Navigator.of(context).push(fadeSlideRoute(
                              const GameScreen(levelId: 'tutorial'),
                            ));
                          },
                          icon: const Icon(Icons.school_rounded),
                          label: const Text('Tutorial'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton.icon(
                        onPressed: () {
                          controller.audio.sfx('ui_tap.wav');
                          Navigator.of(context).push(fadeSlideRoute(
                            const WorldMapScreen(),
                          ));
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(showTutorialCta ? 'Campaign' : 'Play'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: endlessUnlocked
                            ? () {
                                controller.audio.sfx('ui_tap.wav');
                                Navigator.of(context).push(fadeSlideRoute(
                                  const GameScreen(),
                                ));
                              }
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
                        onPressed: () {
                          controller.audio.sfx('ui_tap.wav');
                          Navigator.of(context).push(fadeSlideRoute(
                            const ShopScreen(),
                          ));
                        },
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
                            onPressed: () {
                              controller.audio.sfx('ui_tap.wav');
                              Navigator.of(context).push(fadeSlideRoute(
                                const AchievementsScreen(),
                              ));
                            },
                            icon: const Icon(Icons.emoji_events_outlined),
                            label: const Text('Achievements'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: () {
                              controller.audio.sfx('ui_tap.wav');
                              Navigator.of(context).push(fadeSlideRoute(
                                const TrophyRoomScreen(),
                              ));
                            },
                            icon: const Icon(Icons.military_tech_rounded),
                            label: const Text('Trophies'),
                          ),
                        ],
                      ),
                      if (!showTutorialCta) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            controller.audio.sfx('ui_tap.wav');
                            Navigator.of(context).push(fadeSlideRoute(
                              const GameScreen(levelId: 'tutorial'),
                            ));
                          },
                          child: const Text('Replay tutorial'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: kDebugMode
                      ? () => controller.grantDebugCoins(1000)
                      : null,
                  child: CoinCount(coins: controller.progress.coins, size: 26),
                ),
                IconButton(
                  key: const ValueKey('settings'),
                  tooltip: 'Settings',
                  onPressed: () {
                    controller.audio.sfx('ui_tap.wav');
                    Navigator.of(context).push(fadeSlideRoute(
                      const SettingsScreen(),
                    ));
                  },
                  icon: const Icon(Icons.settings_rounded, color: brandBrown),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
