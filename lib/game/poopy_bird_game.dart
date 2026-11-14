import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../components/bird.dart';
import '../components/car.dart';
import '../components/car_spawner.dart';
import '../components/effects.dart';
import '../components/food_pickup.dart';
import '../components/food_spawner.dart';
import '../components/hud.dart';
import '../components/landing_marker.dart';
import '../components/poop.dart';
import '../components/run_scoped.dart';
import '../components/scenery.dart';
import '../systems/belly.dart';
import '../systems/combo_tracker.dart';
import '../systems/difficulty.dart';
import '../systems/rage_meter.dart';
import '../systems/score_tracker.dart';
import '../ui/game_over_overlay.dart';
import 'config.dart';

enum GameOverReason { crash, rage }

class PoopyBirdGame extends FlameGame
    with TapCallbacks, DragCallbacks, KeyboardEvents, HasCollisionDetection {
  PoopyBirdGame({Random? random}) : random = random ?? Random();

  final Random random;
  final ScoreTracker score = ScoreTracker();
  final RageMeter rage = RageMeter();
  final ComboTracker combo = ComboTracker();
  final Belly belly = Belly();
  final Difficulty difficulty = Difficulty();

  late final Bird bird;
  late final CarSpawner carSpawner;
  late final FoodSpawner foodSpawner;
  late final Hud hud;

  GameOverReason? gameOverReason;
  bool get isGameOver => gameOverReason != null;

  double get scrollSpeed => difficulty.scrollSpeed;

  // ─── Layout ───────────────────────────────────────────────────────────────
  // The camera is anchored top-left, so world coordinates equal screen pixels.

  double get roadHeight => size.y * GameConfig.roadHeightFraction;
  double get roadTop => size.y - roadHeight;
  double laneBaseline(int lane) =>
      roadTop + roadHeight * GameConfig.laneBaselines[lane];

  /// Height at which a falling poop hits the road (the near lane's surface).
  double get poopGroundY => laneBaseline(GameConfig.laneBaselines.length - 1);

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
    foodSpawner = FoodSpawner();
    hud = Hud();

    world.addAll([Scenery(), LandingMarker(), bird, carSpawner, foodSpawner]);
    camera.viewport.add(hud);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;
    score.addDistance(scrollSpeed * dt);
    difficulty.update(dt);
    combo.update(dt);
    belly.update(dt);
  }

  // ─── Rules ────────────────────────────────────────────────────────────────

  void onPoopHitCar(Poop poop, Car car) {
    if (isGameOver) return;
    // A big poop splats every car near the impact, in any lane.
    final targets = poop.kind == PoopKind.big
        ? world.children.whereType<Car>().where((c) =>
            ((c.position.x + c.size.x / 2) - poop.position.x).abs() <=
            GameConfig.bigSplatReach)
        : [car];
    for (final target in targets.toList()) {
      if (target.splat()) _scoreSplat(target);
    }
    world.add(splatBurst(
      poop.position.clone(),
      random,
      count: poop.kind == PoopKind.big ? 28 : 12,
      power: poop.kind == PoopKind.big ? 1.6 : 1,
    ));
  }

  void _scoreSplat(Car car) {
    final multiplier = combo.registerHit();
    final points = score.registerSplat(multiplier: multiplier);
    rage.onCarSplatted();
    world.add(FloatingText(
      multiplier > 1 ? '+$points  x$multiplier' : '+$points',
      position: car.roofCenter - Vector2(0, 16),
      color: multiplier > 1 ? const Color(0xFFFFD600) : const Color(0xFFFFFFFF),
      fontSize: 16 + multiplier * 2.0,
    ));
  }

  void onPoopMissed(Poop poop) {
    if (isGameOver) return;
    combo.registerMiss();
    world.add(RoadSplat(position: poop.position.clone(), radius: poop.radius));
    world.add(splatBurst(poop.position.clone(), random, count: 6, power: 0.6));
  }

  void onCarEscaped(Car car) {
    if (isGameOver) return;
    rage.onCarEscaped();
    if (rage.isFull) gameOver(GameOverReason.rage);
  }

  void onFoodEaten(FoodPickup food) {
    if (isGameOver || food.isRemoving) return;
    belly.eat(food.type);
    food.removeFromParent();
    world.add(FloatingText(
      food.type.label,
      position: food.position.clone(),
      color: const Color(0xFFFFAB40),
    ));
  }

  void onBellyEmpty() => hud.flashEmpty();

  void gameOver(GameOverReason reason) {
    if (isGameOver) return;
    gameOverReason = reason;
    bird.holdingPoop = false;
    score.finishRun();
    pauseEngine();
    overlays.add(GameOverOverlay.id);
  }

  void restart() {
    world.removeAll(world.children.whereType<RunScoped>().toList());
    score.reset();
    rage.reset();
    combo.reset();
    belly.reset();
    difficulty.reset();
    gameOverReason = null;
    _poopPointers.clear();
    bird.reset();
    carSpawner.reset();
    foodSpawner.reset();
    overlays.remove(GameOverOverlay.id);
    resumeEngine();
  }

  // ─── Input ────────────────────────────────────────────────────────────────
  // Touch: left half flaps, right half poops and keeps pooping while held.
  // Each finger is tracked separately, so both halves work at once.

  final Set<int> _poopPointers = {};

  bool _isPoopSide(Vector2 canvasPosition) => canvasPosition.x >= size.x / 2;

  void _releasePointer(int pointerId) {
    _poopPointers.remove(pointerId);
    bird.holdingPoop = _poopPointers.isNotEmpty;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    if (_isPoopSide(event.canvasPosition)) {
      _poopPointers.add(event.pointerId);
      bird.holdingPoop = true;
      bird.poop();
    } else {
      bird.flap();
    }
  }

  @override
  void onTapUp(TapUpEvent event) => _releasePointer(event.pointerId);

  // A held finger that moves turns into a drag and cancels the tap; keep
  // pooping until the finger actually lifts.
  @override
  void onTapCancel(TapCancelEvent event) {}

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isGameOver && _isPoopSide(event.canvasPosition)) {
      _poopPointers.add(event.pointerId);
      bird.holdingPoop = true;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _releasePointer(event.pointerId);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _releasePointer(event.pointerId);
  }

  // Keyboard (desktop/web testing): Space/W/Up flap; hold S/X/Down to poop;
  // Enter/R restart after game over.
  static final Set<LogicalKeyboardKey> _flapKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.arrowUp,
  };
  static final Set<LogicalKeyboardKey> _poopKeys = {
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.arrowDown,
  };

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final key = event.logicalKey;

    if (isGameOver) {
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.keyR)) {
        restart();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    bird.holdingPoop =
        _poopPointers.isNotEmpty || keysPressed.any(_poopKeys.contains);

    if (event is KeyDownEvent && _flapKeys.contains(key)) {
      bird.flap();
      return KeyEventResult.handled;
    }
    return _poopKeys.contains(key)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }
}
