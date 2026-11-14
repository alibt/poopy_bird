import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:flutter/services.dart';

import '../components/bird.dart';
import '../components/car.dart';
import '../components/car_spawner.dart';
import '../components/hud.dart';
import '../components/poop.dart';
import '../components/scenery.dart';
import '../systems/rage_meter.dart';
import '../systems/score_tracker.dart';
import '../ui/game_over_overlay.dart';
import 'config.dart';

enum GameOverReason { crash, rage }

class PoopyBirdGame extends FlameGame
    with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  PoopyBirdGame({Random? random}) : random = random ?? Random();

  final Random random;
  final ScoreTracker score = ScoreTracker();
  final RageMeter rage = RageMeter();

  late final Bird bird;
  late final CarSpawner carSpawner;

  GameOverReason? gameOverReason;
  bool get isGameOver => gameOverReason != null;

  // ─── Layout ───────────────────────────────────────────────────────────────
  // The camera is anchored top-left, so world coordinates equal screen pixels.

  double get roadHeight => size.y * GameConfig.roadHeightFraction;
  double get roadTop => size.y - roadHeight;
  double laneBaseline(int lane) =>
      roadTop + roadHeight * GameConfig.laneBaselines[lane];

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    final frames = await Future.wait([
      for (var i = 1; i <= 8; i++) loadSprite('frame-$i.png'),
    ]);
    bird = Bird(animation: SpriteAnimation.spriteList(frames, stepTime: 0.1));
    carSpawner = CarSpawner();

    world.addAll([Scenery(), bird, carSpawner]);
    camera.viewport.add(Hud());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGameOver) score.addDistance(GameConfig.scrollSpeed * dt);
  }

  // ─── Rules ────────────────────────────────────────────────────────────────

  void onCarSplatted(Car car) {
    if (isGameOver) return;
    score.registerSplat();
    rage.onCarSplatted();
  }

  void onCarEscaped(Car car) {
    if (isGameOver) return;
    rage.onCarEscaped();
    if (rage.isFull) gameOver(GameOverReason.rage);
  }

  void gameOver(GameOverReason reason) {
    if (isGameOver) return;
    gameOverReason = reason;
    score.finishRun();
    pauseEngine();
    overlays.add(GameOverOverlay.id);
  }

  void restart() {
    world.removeAll(
      world.children.where((c) => c is Car || c is Poop).toList(),
    );
    score.reset();
    rage.reset();
    gameOverReason = null;
    bird.reset();
    carSpawner.reset();
    overlays.remove(GameOverOverlay.id);
    resumeEngine();
  }

  // ─── Input ────────────────────────────────────────────────────────────────
  // Touch: left half flaps, right half poops. Each finger is handled
  // separately, so both can be used at once.

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    if (event.canvasPosition.x < size.x / 2) {
      bird.flap();
    } else {
      bird.poop();
    }
  }

  // Keyboard (desktop/web testing): Space/W/Up flap, S/Down/X poop,
  // Enter/R restart after game over.
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (isGameOver) {
      if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.keyR) {
        restart();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.arrowUp) {
      bird.flap();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyX ||
        key == LogicalKeyboardKey.arrowDown) {
      bird.poop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
