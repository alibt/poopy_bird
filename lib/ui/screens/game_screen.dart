import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../economy/rewards.dart';
import '../../game/poopy_bird_game.dart';
import '../../levels/level_definition.dart';
import '../../levels/run_plan.dart';
import '../../monetization/ads.dart';
import '../../progress/level_result.dart';
import '../overlays/level_intro_overlay.dart';
import '../overlays/pause_overlays.dart';
import '../overlays/results_overlay.dart';
import '../widgets.dart';

/// Plays one level, or Endless when [levelId] is null.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.levelId});

  final String? levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Future<PoopyBirdGame> _game = _createGame();

  /// Coins paid for the last run; null until the run has been stored.
  final ValueNotifier<RunReward?> _reward = ValueNotifier(null);

  @override
  void dispose() {
    _reward.dispose();
    super.dispose();
  }

  void _onRunFinished(LevelResult result) {
    _reward.value = null;
    AppScope.read(context).record(result).then((reward) {
      if (mounted) _reward.value = reward;
    });
  }

  Future<PoopyBirdGame> _createGame() async {
    final controller = AppScope.read(context);
    final id = widget.levelId;
    final LevelDefinition? level =
        id == null ? null : await controller.levelRepository.loadLevel(id);
    return PoopyBirdGame(
      plan: level == null ? EndlessPlan() : LevelPlan(level),
      bestScore: level == null
          ? controller.progress.endlessBest
          : controller.progress.recordFor(level.id).bestScore,
      loadout: controller.progress.loadout,
      onRunFinished: _onRunFinished,
    );
  }

  void _quit() => Navigator.of(context).pop();

  void _playNext(String levelId) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => GameScreen(levelId: levelId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PoopyBirdGame>(
      future: _game,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SkyBackground(
            child: Center(
              child: Panel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load this level:\n${snapshot.error}'),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _quit, child: const Text('Back')),
                  ],
                ),
              ),
            ),
          );
        }
        final game = snapshot.data;
        if (game == null) {
          return const SkyBackground(
              child: Center(child: CircularProgressIndicator()));
        }
        return PopScope(
          canPop: false,
          // System back pauses a running game; otherwise it leaves.
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (game.isRunning) {
              game.pause();
            } else {
              _quit();
            }
          },
          child: Scaffold(
            body: GameWidget<PoopyBirdGame>(
              game: game,
              overlayBuilderMap: {
                GameOverlays.intro: (_, g) =>
                    LevelIntroOverlay(game: g, onBack: _quit),
                GameOverlays.pauseButton: (_, g) => PauseButtonOverlay(game: g),
                GameOverlays.pauseMenu: (_, g) =>
                    PauseMenuOverlay(game: g, onQuit: _quit),
                GameOverlays.results: (context, g) {
                  final controller = AppScope.read(context);
                  final levelId = g.plan.level?.id;
                  final next =
                      levelId == null ? null : controller.nextLevelId(levelId);
                  final result = g.lastResult!;
                  return ResultsOverlay(
                    game: g,
                    reward: _reward,
                    onDoubleCoins: controller.ads
                            .isAvailable(AdPlacement.doubleCoins)
                        ? (reward) => controller.doubleRunCoins(reward, result)
                        : null,
                    onQuit: _quit,
                    onNext: next != null && (g.outcome?.isWin ?? false)
                        ? () => _playNext(next)
                        : null,
                  );
                },
              },
            ),
          ),
        );
      },
    );
  }
}
