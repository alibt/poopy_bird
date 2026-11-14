import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poopy_bird/bird.dart';
import 'package:poopy_bird/car.dart';
import 'package:poopy_bird/ground.dart';
import 'package:poopy_bird/tree.dart';
// shared_preferences removed — high score is in-memory until Google Maven
// is reachable from this network and the package can be re-added.;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
  ).then((_) {
    runApp(
      GameWidget(
        game: BirdGame(),
        overlayBuilderMap: {
          'GameOver': (context, game) {
            final g = game as BirdGame;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    g.diedToRage ? 'THE CARS ARE ANGRY!' : 'Game Over',
                    style: TextStyle(
                      fontSize: 32,
                      color: g.diedToRage ? Colors.redAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Score: ${g.score}',
                    style: const TextStyle(fontSize: 24, color: Colors.yellowAccent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Best: ${g.highScore}',
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => g.resumeGame(),
                    child: const Text('Restart'),
                  ),
                ],
              ),
            );
          },
        },
      ),
    );
  });
}

class BirdGame extends FlameGame
    with
        TapCallbacks,
        KeyboardEvents,
        HasCollisionDetection,
        MultiTouchDragDetector {
  // Bird
  late Bird bird;

  // Background
  late List<Street> grounds = [];
  late List<Tree> trees = [];

  // Cars
  final List<Car> topLaneCars = [];
  final List<Car> bottomLaneCars = [];
  late Timer carSpawnTimer;

  // Game speed
  double speed = 120;

  // Score
  int score = 0;
  int highScore = 0;
  late TextComponent _scoreText;
  late TextComponent _highScoreText;

  // Rage meter (0.0 – 1.0). Fills on missed cars, drains on poop hits.
  double _rageMeter = 0.0;
  static const double _rageFillPerMiss = 0.2;   // 5 misses = game over
  static const double _rageDrainPerHit = 0.1;
  late RectangleComponent _rageBarFill;

  // Game-over cause
  bool diedToRage = false;

  @override
  Future<void> onLoad() async {
    _loadHighScore();

    carSpawnTimer = Timer(2, repeat: true, onTick: spawnCar);
    carSpawnTimer.start();

    // Bird animation frames
    final frames = await Future.wait([
      for (int i = 1; i <= 8; i++) Sprite.load('frame-$i.png'),
    ]);
    final birdAnimation = SpriteAnimation.spriteList(frames, stepTime: 0.1);

    // Ground tiles
    for (int i = 0; i < 5; i++) {
      final street = Street(
        position: Vector2(i * size.x, size.y / 2),
        size: Vector2(size.x, 200),
      );
      grounds.add(street);
      add(street);
    }

    // Trees
    for (int i = 0; i < 6; i++) {
      final tree = Tree(
        position: Vector2(i * 300 + 200 + (i % 2) * 100, size.y - 250),
      );
      trees.add(tree);
      add(tree);
    }

    // Bird
    bird = Bird(
      animation: birdAnimation,
      position: Vector2(size.x * 0.2, size.y * 0.3),
    );
    add(bird);

    // --- UI (added last so it renders on top) ---

    // Rage bar background (full width, 10px tall)
    add(RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(size.x, 10),
      paint: Paint()..color = const Color(0x44220000),
    ));

    // Rage bar fill
    _rageBarFill = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(0, 10),
      paint: Paint()..color = const Color(0xFFFF2200),
    );
    add(_rageBarFill);

    // Rage label
    add(TextComponent(
      text: 'RAGE',
      position: Vector2(8, 1),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF6644),
          fontSize: 8,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    ));

    // Score (top-left)
    _scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(16, 14),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
    );
    add(_scoreText);

    // High score (top-right)
    _highScoreText = TextComponent(
      text: 'Best: $highScore',
      position: Vector2(size.x - 16, 14),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
    );
    add(_highScoreText);

    return super.onLoad();
  }

  // ─── Score ────────────────────────────────────────────────────────────────

  void addScore(int points) {
    score += points;
    _scoreText.text = 'Score: $score';
  }

  // High score is kept in-memory (persists within the app session).
  // Persistence via shared_preferences can be re-added once Google Maven
  // is accessible from this network.
  void _loadHighScore() {
    highScore = 0;
  }

  void _saveHighScore() {
    if (score > highScore) highScore = score;
  }

  // ─── Rage meter ───────────────────────────────────────────────────────────

  void onCarMissed() {
    _rageMeter = min(1.0, _rageMeter + _rageFillPerMiss);
    _rageBarFill.size.x = size.x * _rageMeter;
    if (_rageMeter >= 1.0) {
      diedToRage = true;
      gameOver();
    }
  }

  void onPoopHitCar() {
    addScore(50);
    _rageMeter = max(0.0, _rageMeter - _rageDrainPerHit);
    _rageBarFill.size.x = size.x * _rageMeter;
  }

  // ─── Spawning ─────────────────────────────────────────────────────────────

  void spawnCar() {
    final random = Random();
    final streetTop = size.y - 200;
    final topLaneY = streetTop + 40;
    final bottomLaneY = streetTop + 120;
    final laneY = random.nextBool() ? topLaneY : bottomLaneY;
    final laneCars = laneY == topLaneY ? topLaneCars : bottomLaneCars;

    if (laneCars.isNotEmpty && laneCars.last.position.x > size.x - 250) return;

    final car = Car(
      position: Vector2(size.x + 100, laneY),
      size: Vector2(80, 40),
      color: Colors.primaries[random.nextInt(Colors.primaries.length)],
      speed: 120 + random.nextDouble() * 100,
      laneList: laneCars,
      onMissed: onCarMissed,
    );

    laneCars.add(car);
    add(car);
  }

  // ─── Game loop ────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    carSpawnTimer.update(dt);

    // Distance-based score
    addScore((speed * dt / 10).round());

    for (final ground in grounds) {
      ground.position.x -= speed * dt;
      if (ground.position.x < -ground.size.x) {
        ground.position.x += grounds.length * ground.size.x;
      }
    }

    for (final tree in trees) {
      tree.position.x -= speed * dt;
      if (tree.position.x < -100) {
        tree.position.x += size.x + 800;
      }
    }
  }

  // ─── Input — Option A: left = flap, right = poop ─────────────────────────

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    final x = info.eventPosition.global.x;
    if (x < size.x / 2) {
      bird.jump();
    } else {
      bird.poop();
    }
  }

  // onDragUpdate and onDragCancel intentionally left as no-ops;
  // bird movement is now physics-only.

  @override
  void onTapDown(TapDownEvent event) {
    final x = event.canvasPosition.x;
    if (x < size.x / 2) {
      bird.jump();
    } else {
      bird.poop();
    }
  }

  // ─── Game state ───────────────────────────────────────────────────────────

  void gameOver() {
    _saveHighScore(); // fire-and-forget
    pauseEngine();
    overlays.add('GameOver');
  }

  void resumeGame() {
    // Reset state
    score = 0;
    diedToRage = false;
    _rageMeter = 0.0;
    _rageBarFill.size.x = 0;
    _scoreText.text = 'Score: 0';
    _highScoreText.text = 'Best: $highScore';

    // Reset bird
    bird.position = Vector2(size.x * 0.2, size.y * 0.3);
    bird.speedY = 0;

    // Clear cars
    for (final car in [...topLaneCars, ...bottomLaneCars]) {
      car.removeFromParent();
    }
    topLaneCars.clear();
    bottomLaneCars.clear();

    // Reset backgrounds
    for (int i = 0; i < grounds.length; i++) {
      grounds[i].position = Vector2(i * size.x, size.y / 2);
    }
    for (int i = 0; i < trees.length; i++) {
      trees[i].position = Vector2(i * 300 + 200 + (i % 2) * 100, size.y - 250);
    }

    carSpawnTimer.start();
    overlays.remove('GameOver');
    resumeEngine();
  }
}
