import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: GameWidget(
          game: CollectorGame(),
          overlayBuilderMap: {
            'gameOver': (BuildContext context, CollectorGame gameRef) {
              return GameOverMenu(game: gameRef);
            },
          },
        ),
      ),
    ),
  );
}

// Game over overlay widget
class GameOverMenu extends StatelessWidget {
  final CollectorGame game;

  const GameOverMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Score: ${game.score}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Remove the overlay and restart the game
                game.overlays.remove('gameOver');
                game.reset();
                game.resumeEngine();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// Main game class
class CollectorGame extends FlameGame with HasCollisionDetection, TapCallbacks, DragCallbacks {
  // Game properties
  late Player player;
  late TextComponent scoreText;
  int score = 0;
  final _random = math.Random();
  double gameTime = 0.0;
  double itemSpawnTime = 0.0;
  double obstacleSpawnTime = 0.0;

  @override
  Future<void> onLoad() async {
    // Add background (use a colored rectangle for now)
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF333333),
    )..priority = -1);

    // Add player
    player = Player();
    add(player);

    // Add score display
    scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24.0,
        ),
      ),
    );
    scoreText.position = Vector2(20, 20);
    add(scoreText);

    // Initialize collision detection
    add(ScreenHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    gameTime += dt;
    itemSpawnTime += dt;
    obstacleSpawnTime += dt;

    // Spawn collectible items every 1.5 seconds
    if (itemSpawnTime > 1.5) {
      spawnCollectible();
      itemSpawnTime = 0;
    }

    // Spawn obstacles every 2.5 seconds
    if (obstacleSpawnTime > 2.5) {
      spawnObstacle();
      obstacleSpawnTime = 0;
    }
  }

  void spawnCollectible() {
    final collectible = Collectible();
    collectible.position = Vector2(
      _random.nextDouble() * (size.x - 40),
      _random.nextDouble() * (size.y - 40),
    );
    add(collectible);
  }

  void spawnObstacle() {
    final obstacle = Obstacle();
    obstacle.position = Vector2(
      _random.nextDouble() * (size.x - 60),
      _random.nextDouble() * (size.y - 60),
    );
    add(obstacle);
  }

  void increaseScore() {
    score++;
    scoreText.text = 'Score: $score';
  }

  @override
  void onTapDown(TapDownEvent event) {
    player.moveTo(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    player.position.add(event.canvasDelta);
  }

  void reset() {
    // Remove all game components except the background and player
    children.whereType<Collectible>().forEach((child) => child.removeFromParent());
    children.whereType<Obstacle>().forEach((child) => child.removeFromParent());

    // Reset score
    score = 0;
    scoreText.text = 'Score: 0';

    // Reset timers
    gameTime = 0.0;
    itemSpawnTime = 0.0;
    obstacleSpawnTime = 0.0;

    // Reset player position
    player.position = size / 2;
    player.targetPosition = null;
  }
}

// Player component
class Player extends CircleComponent with CollisionCallbacks, HasGameRef<CollectorGame> {
  final double speed = 300;
  Vector2? targetPosition;

  Player() : super(
    radius: 25,
    paint: Paint()..color = Colors.blue,
  ) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = gameRef.size / 2;
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move player towards target position if set
    if (targetPosition != null) {
      final direction = targetPosition! - position;
      if (direction.length > 5) { // If not close enough to target
        direction.normalize();
        position += direction * speed * dt;
      } else {
        targetPosition = null; // Reached the target
      }
    }

    // Keep player within game bounds
    position.clamp(
      Vector2(radius, radius),
      gameRef.size - Vector2(radius, radius),
    );
  }

  void moveTo(Vector2 target) {
    targetPosition = target;
  }
}

// Collectible item component
class Collectible extends CircleComponent with CollisionCallbacks, HasGameRef<CollectorGame> {
  Collectible() : super(
    radius: 15,
    paint: Paint()..color = Colors.green,
  ) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other
      ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      gameRef.increaseScore();
      removeFromParent();
    }
  }
}

// Obstacle component
class Obstacle extends CircleComponent with CollisionCallbacks, HasGameRef<CollectorGame> {
  Obstacle() : super(
    radius: 20,
    paint: Paint()..color = Colors.red,
  ) {
    add(CircleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.center;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints,
      PositionComponent other
      ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      gameRef.overlays.add('gameOver');
      gameRef.pauseEngine();
    }
  }
}