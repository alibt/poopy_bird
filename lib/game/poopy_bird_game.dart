import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, KeyEventResult;

import '../components/attacker_spawner.dart';
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
import '../audio/game_audio.dart';
import '../economy/catalog.dart';
import '../juice/feedback.dart';
import '../levels/run_plan.dart';
import '../progress/level_result.dart';
import '../systems/belly.dart';
import '../systems/combo_tracker.dart';
import '../systems/objective_tracker.dart';
import '../systems/rage_meter.dart';
import '../systems/run_stats.dart';
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
    this.loadout = const Loadout(),
    this.onRunFinished,
    GameFeedback? feedback,
    this.leftHanded = false,
  })  : plan = plan ?? EndlessPlan(),
        random = random ?? Random(),
        score = ScoreTracker(best: bestScore),
        feedback = feedback ?? GameFeedback(audio: GameAudio());

  final RunPlan plan;
  final Random random;
  final ScoreTracker score;

  /// Upgrades and cosmetics for this run.
  final Loadout loadout;

  /// Audio + haptics + shake for this run.
  final GameFeedback feedback;

  /// Swap flap/poop screen halves.
  final bool leftHanded;

  /// Called once when a run ends. The app layer stores the result; the game
  /// itself never touches storage or the network.
  final void Function(LevelResult result)? onRunFinished;

  late final RageMeter rage =
      RageMeter(fillPerEscape: plan.rageFillPerEscape * loadout.rageFillScale);
  late final ComboTracker combo = ComboTracker(window: loadout.comboWindow);
  late final Belly belly = Belly(
    capacity: loadout.bellyCapacity,
    digestionInterval: loadout.digestionInterval,
    chiliDuration: loadout.chiliDuration,
    burritoBigPoops: loadout.burritoBigPoops,
  );
  late ObjectiveTracker objectives = ObjectiveTracker(plan.objectives);
  final RunStats stats = RunStats();

  late final Bird bird;
  late final CarSpawner carSpawner;
  late final FoodSpawner foodSpawner;
  late final Hud hud;

  /// Seconds of play this run.
  double elapsed = 0;

  /// 0–1 soft ceiling push from missed cars. Food follows this band.
  double altitudePressure = 0;

  /// Levels wait on their intro screen until [startRun]; Endless starts
  /// straight away.
  late bool started = plan.level == null;

  bool isPausedByPlayer = false;

  RunOutcome? outcome;
  LevelResult? lastResult;

  /// World index 1–5 from level id (`w3_l1` → 3), or 0 for Endless.
  int get worldNumber {
    final id = plan.level?.id;
    if (id == null || id.length < 2 || id[0] != 'w') return 0;
    return int.tryParse(id[1]) ?? 0;
  }

  /// High worlds (and late Endless) spawn roadside shooters.
  bool get attackersEnabled =>
      worldNumber >= 3 || (worldNumber == 0 && elapsed > 45);

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

  /// Lane closest to the bird's height — used for the landing aim shadow.
  int get aimLane {
    final birdY = bird.position.y;
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < GameConfig.laneBaselines.length; i++) {
      final y = laneBaseline(i);
      final dist = (y - birdY).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  double get aimGroundY => laneBaseline(aimLane);

  /// Y the bird settles to. Misses/time push it down; hits lift it.
  double get cruiseY {
    final high = size.y * GameConfig.cruiseHighFraction;
    final low = size.y * GameConfig.cruiseLowFraction;
    return high + (low - high) * altitudePressure.clamp(0.0, 1.0);
  }

  double get foodBandTop => size.y * GameConfig.foodBandTopFraction;
  double get foodBandBottom => size.y * GameConfig.foodBandBottomFraction;

  /// Bird below this Y is in the attacker danger band.
  double get attackerDangerY => size.y * GameConfig.attackerDangerFraction;

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    final frames = await Future.wait([
      for (var i = 1; i <= 8; i++) loadSprite('bird_${i.toString().padLeft(2, '0')}.png'),
    ]);
    bird = Bird(
      animation: SpriteAnimation.spriteList(frames, stepTime: 0.07),
      hue: loadout.birdHue,
    );
    carSpawner = CarSpawner();
    foodSpawner = FoodSpawner();
    hud = Hud();

    world.addAll([
      Scenery(),
      LandingMarker(),
      bird,
      carSpawner,
      foodSpawner,
      AttackerSpawner(),
    ]);
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
    // Time slowly sinks cruise altitude — hits are the way back up.
    altitudePressure = min(
      1,
      altitudePressure + GameConfig.altitudePressurePerSecond * dt,
    );
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
    bird.diving = false;
    _poopPointers.clear();
    _divePointers.clear();
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
    feedback.audio.stopMusic();
    if (result == RunOutcome.crashed || result == RunOutcome.rageOut) {
      feedback.audio.sfx('crash.wav');
      feedback.hapticHeavy();
      feedback.shake(camera, intensity: 10, pulses: 4);
    }
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
      isBoss: level?.isBoss ?? false,
      runId: LevelResult.newRunId(),
      distance: score.distanceMetres,
      poopsDropped: stats.poopsDropped,
      poopsMissed: stats.poopsMissed,
      foodEaten: stats.foodEaten,
      bossesDefeated: stats.bossesDefeated,
      maxRage: stats.maxRage,
      bestMultiSplat: stats.bestMultiSplat,
      splatsByType: Map.of(stats.splatsByType),
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
    stats.reset();
    objectives = ObjectiveTracker(plan.objectives);
    elapsed = 0;
    altitudePressure = 0;
    outcome = null;
    lastResult = null;
    started = true;
    isPausedByPlayer = false;
    _poopPointers.clear();
    _divePointers.clear();
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
    // Big poops and dive-bombs splash nearby cars in any lane.
    final reach = poop.kind == PoopKind.big
        ? GameConfig.bigSplatReach
        : (poop.diveBomb ? GameConfig.diveSplatReach : 0.0);
    final targets = reach > 0
        ? world.children.whereType<Car>().where(
            (c) => (c.centerX - poop.position.x).abs() <= reach)
        : [car];
    var splatted = 0;
    for (final target in targets.toList()) {
      if (target.splat()) {
        _scoreHit(target, diveBomb: poop.diveBomb);
        if (target.isSplatted) splatted++;
      }
    }
    stats.onPoopLanded(splatted);
    feedback.audio.sfx('splat.wav');
    feedback.hapticMedium();
    final juicy = poop.kind == PoopKind.big || poop.diveBomb;
    feedback.shake(camera, intensity: juicy ? 8 : 5);
    world.add(splatBurst(
      poop.position.clone(),
      random,
      color: loadout.poopColor,
      count: juicy ? 28 : 12,
      power: juicy ? 1.6 : 1,
    ));
    if (poop.diveBomb && splatted > 0) {
      world.add(FloatingText(
        'DIVE!',
        position: poop.position.clone() - Vector2(0, 24),
        color: const Color(0xFFFFAB40),
        fontSize: 20,
      ));
    }
  }

  void _scoreHit(Car car, {bool diveBomb = false}) {
    final multiplier = combo.registerHit();
    final base = diveBomb
        ? (car.type.points * GameConfig.diveScoreBonus).round()
        : car.type.points;
    final points = score.registerHit(basePoints: base, multiplier: multiplier);
    onAltitudeFromHit();
    if (multiplier > 1) feedback.audio.sfx('combo.wav', volume: 0.7);
    if (car.type.raisesRageOnHit) {
      rage.onCarEscaped();
      stats.onRage(rage.value);
      if (rage.isFull) {
        finish(RunOutcome.rageOut);
        return;
      }
    } else {
      rage.onCarSplatted();
    }
    objectives.onCombo(combo.count);
    world.add(FloatingText(
      multiplier > 1 ? '+$points  x$multiplier' : '+$points',
      position: car.roofCenter - Vector2(0, 16),
      color: multiplier > 1 ? const Color(0xFFFFD600) : const Color(0xFFFFFFFF),
      fontSize: 16 + multiplier * 2.0,
    ));
    if (car.isSplatted) {
      score.registerCarSplatted();
      stats.onCarSplatted(car.type);
      objectives.onSplat(car.type);
      if (car.type.isBoss) _onBossDefeated(car);
    }
  }

  void _onBossDefeated(Car boss) {
    objectives.onBossDefeated();
    score.addBonus(GameConfig.bossBonus);
    boss.speed *= 2.5;
    world.add(splatBurst(boss.roofCenter, random,
        color: loadout.poopColor, count: 60, power: 2));
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
    stats.onPoopMissed();
    feedback.audio.sfx('miss.wav', volume: 0.6);
    world.add(RoadSplat(
      position: poop.position.clone(),
      radius: poop.radius,
      color: loadout.poopColor,
    ));
    world.add(splatBurst(poop.position.clone(), random,
        color: loadout.poopColor, count: 6, power: 0.6));
  }

  void onCarEscaped(Car car) {
    if (isFinished) return;
    objectives.onEscape();
    rage.onCarEscaped();
    stats.onRage(rage.value);
    altitudePressure = min(
      1,
      altitudePressure + GameConfig.altitudePressurePerEscape,
    );
    if (rage.isFull) finish(RunOutcome.rageOut);
  }

  void onAltitudeFromHit() {
    altitudePressure = max(
      0,
      altitudePressure - GameConfig.altitudePressurePerHit,
    );
  }

  void onFoodEaten(FoodPickup food) {
    if (isFinished || food.isRemoving) return;
    belly.eat(food.type);
    stats.onFoodEaten();
    food.removeFromParent();
    feedback.audio.sfx('eat.wav');
    feedback.hapticLight();
    world.add(FloatingText(
      food.type.label,
      position: food.position.clone(),
      color: const Color(0xFFFFAB40),
    ));
  }

  void onBellyEmpty() {
    hud.flashEmpty();
    feedback.hapticLight();
  }

  // ─── Input ────────────────────────────────────────────────────────────────
  // Touch (left-handed swaps sides):
  //   Control side upper = flap, lower = hold to dive-bomb.
  //   Poop side = hold to poop.
  // Keyboard: Space/W/Up flap; S/X poop; ArrowDown dive; Esc/P pause.

  final Set<int> _poopPointers = {};
  final Set<int> _divePointers = {};

  bool _isPoopSide(Vector2 canvasPosition) {
    final right = canvasPosition.x >= size.x / 2;
    return leftHanded ? !right : right;
  }

  /// Lower half of the flap side = dive hold.
  bool _isDiveZone(Vector2 canvasPosition) =>
      !_isPoopSide(canvasPosition) && canvasPosition.y >= size.y * 0.55;

  void _onFlap() {
    bird.flap();
    feedback.audio.sfx('flap.wav', volume: 0.5);
  }

  void _onPoopAttempt() => bird.poop();

  void _syncDive() {
    bird.diving = _divePointers.isNotEmpty;
  }

  void _releasePointer(int pointerId) {
    _poopPointers.remove(pointerId);
    _divePointers.remove(pointerId);
    bird.holdingPoop = _poopPointers.isNotEmpty;
    _syncDive();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isRunning) return;
    final pos = event.canvasPosition;
    if (_isPoopSide(pos)) {
      _poopPointers.add(event.pointerId);
      bird.holdingPoop = true;
      _onPoopAttempt();
    } else if (_isDiveZone(pos)) {
      _divePointers.add(event.pointerId);
      _syncDive();
    } else {
      _onFlap();
    }
  }

  @override
  void onTapUp(TapUpEvent event) => _releasePointer(event.pointerId);

  @override
  void onTapCancel(TapCancelEvent event) {}

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isRunning) return;
    final pos = event.canvasPosition;
    if (_isPoopSide(pos)) {
      _poopPointers.add(event.pointerId);
      bird.holdingPoop = true;
    } else if (_isDiveZone(pos)) {
      _divePointers.add(event.pointerId);
      _syncDive();
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

  static final Set<LogicalKeyboardKey> _flapKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.arrowUp,
  };
  static final Set<LogicalKeyboardKey> _poopKeys = {
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyX,
  };
  static final Set<LogicalKeyboardKey> _diveKeys = {
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
    bird.diving =
        _divePointers.isNotEmpty || keysPressed.any(_diveKeys.contains);

    if (down && _flapKeys.contains(key)) {
      _onFlap();
      return KeyEventResult.handled;
    }
    if (_poopKeys.contains(key) || _diveKeys.contains(key)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
