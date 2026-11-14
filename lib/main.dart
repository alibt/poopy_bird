import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/poopy_bird_game.dart';
import 'ui/game_over_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const PoopyBirdApp());
}

class PoopyBirdApp extends StatefulWidget {
  const PoopyBirdApp({super.key});

  @override
  State<PoopyBirdApp> createState() => _PoopyBirdAppState();
}

class _PoopyBirdAppState extends State<PoopyBirdApp> {
  // Held in state so widget rebuilds (and hot reload) keep the same game.
  final PoopyBirdGame _game = PoopyBirdGame();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poopy Bird',
      debugShowCheckedModeBanner: false,
      home: GameWidget<PoopyBirdGame>(
        game: _game,
        overlayBuilderMap: {
          GameOverOverlay.id: (context, game) => GameOverOverlay(game: game),
        },
      ),
    );
  }
}
