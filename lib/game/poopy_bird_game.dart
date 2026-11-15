import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, KeyEventResult;

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
import '../levels/run_plan.dart';
import '../progress/level_result.dart';
import '../systems/belly.dart';
import '../systems/combo_tracker.dart';
import '../systems/objective_tracker.dart';
import '../systems/rage_meter.dart';
import '../systems/score_tracker.dart';
import 'config.dart';

/// Names of the Flutter overlays the game shows. The UI layer registers a
/// builder for each.
abstract final class GameOverlays {
  static const String intro = 'LevelIntro';
  static const String pauseButton = 'PauseButton';
  static const String pauseMenu = 'PauseMenu';
  static const String results = 'Results';
}

class PoopyBirdGame extends FlameGame
    with TapCallbacks, DragCallbacks, KeyboardEvents, HasCollisionDetection {
  PoopyBirdGame({
    RunPlan? plan,
    Random? random,
    int bestScore = 0,
    this.onRunFinished,
  })  : plan = plan ?? EndlessPlan(),
        random = random ?? Random(),
        score = ScoreTracker(best: bestScore);

  final RunPlan plan;
  final Random random;
  final ScoreTracker score;

  /// Called once when a run ends. The app layer stores the result; the game
  /// itself never touches storage or the network.
  final void Function(LevelResult result)? onRunFinished;

  late final RageMeter rage = RageMeter(fillPerEscape: plan.rageFillPerEscape);
  final ComboTracker combo = ComboTracker();
  final Belly belly = Belly();
  late ObjectiveTracker objectives = ObjectiveTracker(plan.objectives);

  late final Bird bird;
  late final CarSpawner carSpawner;
  late final FoodSpawner foodSpawner;
  late final Hud hud;

  /// Seconds of play this run.
  double elapsed = 0;

  /// Levels wait on their intro screen until [startRun]; Endless starts
  /// straight away.
  late bool started = plan.level == null;

  bool isPausedByPlayer = false;

  RunOutcome? outcome;
  LevelResult? lastResult;

  bool get isFinished => outcome != null;
  bool get isRunning => started && !isFinished && !isPausedByPlayer;

  double get scrollSpeed => plan.scrollSpeedAt(elapsed);

  /// Seconds left in a timed level, or null.
  double? get timeLeft {
    final limit = plan.timeLimit;
    return limit == null ? null : max(0, limit - elapsed);
  }

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

    if (started) {
      _showIfRegistered(GameOverlays.pauseButton);
    } else {
      _showIfRegistered(GameOverlays.intro);
    }
  }

  @override
  void update(double dt) {
    if (!started) {
      // Mount components and draw the scene, but hold everything still.
      super.update(0);
      return;
    }
    super.update(dt);
    if (isFinished) return;
    elapsed += dt;
    score.addDistance(scrollSpeed * dt);
    combo.update(dt);
    belly.update(dt);
    objectives.onScore(score.score);
    _checkEnd();
  }

  void _checkEnd() {
    if (isFinished) return;
    if (objectives.anyFailed) {
      finish(RunOutcome.objectiveFailed);
    } else if (plan.endWhenObjectivesMet &&
        plan.objectives.isNotEmpty &&
        objectives.allMet) {
      finish(RunOutcome.won);
    } else if (plan.timeLimit != null && elapsed >= plan.timeLimit!) {
      finish(objectives.allMet ? RunOutcome.won : RunOutcome.timeUp);
    }
  }

  // ─── Run flow ─────────────────────────────────────────────────────────────

  /// Starts a level after its intro.
  void startRun() {
    started = true;
    overlays.remove(GameOverlays.intro);
    _showIfRegistered(GameOverlays.pauseButton);
  }

  void pause() {
    if (!isRunning) return;
    isPausedByPlayer = true;
    bird.holdingPoop = false;
    _poopPointers.clear();
    pauseEngine();
    _showIfRegistered(GameOverlays.pauseMenu);
  }

  void resume() {
    if (!isPausedByPlayer) return;
    isPausedByPlayer = false;
    overlays.remove(GameOverlays.pauseMenu);
    resumeEngine();
  }

  /// Ends the run. Safe to call more than once; only the first call counts.
  void finish(RunOutcome result) {
    if (isFinished) return;
    outcome = result;
    bird.holdingPoop = false;
    score.finishRun();
    final level = plan.level;
    final stars =
        level?.stars.starsFor(won: result.isWin, score: score.score) ?? 0;
    lastResult = LevelResult(
      levelId: level?.id ?? LevelResult.endlessId,
      levelVersion: level?.version ?? 1,
      outcome: result,
      stars: stars,
      score: score.score,
      carsSplatted: score.carsSplatted,
      bestCombo: combo.best,
      escapes: objectives.escapes,
      durationSeconds: elapsed,
      finishedAt: DateTime.now().toUtc(),
    );
    pauseEngine();
    overlays.remove(GameOverlays.pauseButton);
    onRunFinished?.call(lastResult!);
    _showIfRegistered(GameOverlays.results);
  }

  /// Replays the same run from the start, skipping the intro.
  void restart() {
    world.removeAll(world.children.whereType<RunScoped>().toList());
    score.reset();
    rage.reset();
    combo.reset();
    belly.reset();
    objectives = ObjectiveTracker(plan.objectives);
    elapsed = 0;
    outcome = null;
    lastResult = null;
    started = true;
    isPausedByPlayer = false;
    _poopPointers.clear();
    bird.reset();
    carSpawner.reset();
    foodSpawner.reset();
    overlays.removeAll(
        [GameOverlays.results, GameOverlays.pauseMenu, GameOverlays.intro]);
    _showIfRegistered(GameOverlays.pauseButton);
    resumeEngine();
  }

  void _showIfRegistered(String overlay) {
    if (overlays.registeredOverlays.contains(overlay)) overlays.add(overlay);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    // Show the pause menu when the app is backgrounded, instead of silently
    // resuming when it comes back.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      pause();
    }
    super.lifecycleStateChange(state);
  }

  // ─── Rules ────────────────────────────────────────────────────────────────

  void onPoopHitCar(Poop poop, Car car) {
    if (isFinished) return;
    // A big poop splats every car near the impact, in any lane.
    final targets = poop.kind == PoopKind.big
        ? world.children.whereType<Car>().where((c) =>
            (c.centerX - poop.position.x).abs() <= GameConfig.bigSplatReach)
        : [car];
    for (final target in targets.toList()) {
      if (target.splat()) _scoreHit(target);
    }
    world.add(splatBurst(
      poop.position.clone(),
      random,
      count: poop.kind == PoopKind.big ? 28 : 12,
      power: poop.kind == PoopKind.big ? 1.6 : 1,
    ));
  }

  void _scoreHit(Car car) {
    final multiplier = combo.registerHit();
    final points =
        score.registerHit(basePoints: car.type.points, multiplier: multiplier);
    rage.onCarSplatted();
    objectives.onCombo(combo.count);
    world.add(FloatingText(
      multiplier > 1 ? '+$points  x$multiplier' : '+$points',
      position: car.roofCenter - Vector2(0, 16),
      color: multiplier > 1 ? const Color(0xFFFFD600) : const Color(0xFFFFFFFF),
      fontSize: 16 + multiplier * 2.0,
    ));
    if (car.isSplatted) {
      score.registerCarSplatted();
      objectives.onSplat(car.type);
      if (car.type.isBoss) _onBossDefeated(car);
    }
  }

  void _onBossDefeated(Car boss) {
    objectives.onBossDefeated();
    score.addBonus(GameConfig.bossBonus);
    boss.speed *= 2.5;
    world.add(splatBurst(boss.roofCenter, random, count: 60, power: 2));
    world.add(FloatingText(
      'BOSS DOWN!  +${GameConfig.bossBonus}',
      position: boss.roofCenter - Vector2(0, 40),
      color: const Color(0xFFFFD600),
      fontSize: 28,
    ));
  }

  void onPoopMissed(Poop poop) {
    if (isFinished) return;
    combo.registerMiss();
    world.add(RoadSplat(position: poop.position.clone(), radius: poop.radius));
    world.add(splatBurst(poop.position.clone(), random, count: 6, power: 0.6));
  }

  void onCarEscaped(Car car) {
    if (isFinished) return;
    objectives.onEscape();
    rage.onCarEscaped();
    if (rage.isFull) finish(RunOutcome.rageOut);
  }

  void onFoodEaten(FoodPickup food) {
    if (isFinished || food.isRemoving) return;
    belly.eat(food.type);
    food.removeFromParent();
    world.add(FloatingText(
      food.type.label,
      position: food.position.clone(),
      color: const Color(0xFFFFAB40),
    ));
  }

  void onBellyEmpty() => hud.flashEmpty();

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
    if (!isRunning) return;
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
    if (isRunning && _isPoopSide(event.canvasPosition)) {
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
  // Esc/P pause; Enter starts a level or restarts after the run ends.
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
  static final Set<LogicalKeyboardKey> _pauseKeys = {
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.keyP,
  };

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final key = event.logicalKey;
    final down = event is KeyDownEvent;

    if (down && key == LogicalKeyboardKey.enter) {
      if (!started) {
        startRun();
      } else if (isFinished) {
        restart();
      }
      return KeyEventResult.handled;
    }
    if (down && _pauseKeys.contains(key)) {
      isPausedByPlayer ? resume() : pause();
      return KeyEventResult.handled;
    }
    if (!isRunning) return KeyEventResult.ignored;

    bird.holdingPoop =
        _poopPointers.isNotEmpty || keysPressed.any(_poopKeys.contains);

    if (down && _flapKeys.contains(key)) {
      bird.flap();
      return KeyEventResult.handled;
    }
    return _poopKeys.contains(key)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }
}
