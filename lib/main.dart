import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poopy_bird/bird.dart';
import 'package:poopy_bird/car.dart';
import 'package:poopy_bird/ground.dart';
import 'package:poopy_bird/tree.dart';

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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Game Over',
                      style: TextStyle(fontSize: 32, color: Colors.white)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      (game as BirdGame).resumeGame();
                    },
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
        TapDetector,
        KeyboardEvents,
        HasCollisionDetection,
        MultiTouchDragDetector {
  // Bird component
  late Bird bird;
  bool isDraggingBird = false;
  final Map<int, String> activePointers = {}; // pointerId -> 'drag' or 'poop'

  // Background components
  late List<Street> grounds = [];
  late List<Tree> trees = [];

  final List<Car> topLaneCars = [];
  final List<Car> bottomLaneCars = [];
  late Timer carSpawnTimer;

  // Game variables
  double speed = 120;

  @override
  void onDragStart(int pointerId, DragStartInfo info) {
    final gamePosition = info.eventPosition.global;

    if (gamePosition.x < size.x / 2) {
      // Left side -> drag
      activePointers[pointerId] = 'drag';
      bird.startDragging();
    } else {
      // Right side -> poop
      activePointers[pointerId] = 'poop';
      bird.poop();
    }
  }

  @override
  void onDragUpdate(int pointerId, DragUpdateInfo info) {
    if (activePointers[pointerId] == 'drag') {
      bird.position += info.delta.global;
    }
  }

  @override
  void onDragEnd(int pointerId, DragEndInfo info) {
    if (activePointers[pointerId] == 'drag') {
      bird.stopDragging();
    }
    activePointers.remove(pointerId);
  }

  @override
  void onDragCancel(int pointerId) {
    if (activePointers[pointerId] == 'drag') {
      bird.stopDragging();
    }
    activePointers.remove(pointerId);
  }

  @override
  Future<void> onLoad() async {
    carSpawnTimer = Timer(2, repeat: true, onTick: spawnCar);
    carSpawnTimer.start();

    // Load bird sprite frames for animation
    final frame1 = await Sprite.load('frame-1.png');
    final frame2 = await Sprite.load('frame-2.png');
    final frame3 = await Sprite.load('frame-3.png');
    final frame4 = await Sprite.load('frame-4.png');
    final frame5 = await Sprite.load('frame-5.png');
    final frame6 = await Sprite.load('frame-6.png');
    final frame7 = await Sprite.load('frame-7.png');
    final frame8 = await Sprite.load('frame-8.png');

    // Create sprite animation for bird
    final birdAnimation = SpriteAnimation.spriteList(
      [frame1, frame2, frame3, frame4, frame5, frame6, frame7, frame8],
      stepTime: 0.1, // time between frames
    );

    // Initialize background - sky is the game background color
    // camera. = const Color(0xFF87CEEB); // Sky blue color
    // camera.world?.debugColor = const Color(0xFF87CEEB);

    // Add ground components for infinite scrolling
    for (int i = 0; i < 5; i++) {
      final street = Street(
        position: Vector2(i * size.x, (size.y / 2)),
        size: Vector2(size.x, 200),
      );
      grounds.add(street);
      add(street);
    }

    // Add some trees
    for (int i = 0; i < 6; i++) {
      final tree = Tree(
        position: Vector2(
          i * 300 + 200 + (i % 2) * 100,
          size.y - 100 - 150,
        ),
      );
      trees.add(tree);
      add(tree);
    }

    // Add bird component to game
    bird = Bird(
      animation: birdAnimation,
      position: Vector2(size.x * 0.2, size.y * 0.3),
    );
    add(bird);

    return super.onLoad();
  }

  void spawnCar() {
    final random = Random();
    final streetTop = size.y - 200;
    final topLaneY = streetTop + 40;
    final bottomLaneY = streetTop + 120;
    final laneY = random.nextBool() ? topLaneY : bottomLaneY;

    final laneCars = laneY == topLaneY ? topLaneCars : bottomLaneCars;

    // Don't spawn if the last car is too close
    if (laneCars.isNotEmpty) {
      final lastCar = laneCars.last;
      if (lastCar.position.x > size.x - 250) return;
    }

    final car = Car(
      position: Vector2(size.x + 100, laneY),
      size: Vector2(80, 40),
      color: Colors.primaries[random.nextInt(Colors.primaries.length)],
      speed: 120 + random.nextDouble() * 100,
      // Random speed between 120 and 170
      laneList: laneCars,
    );

    laneCars.add(car);
    add(car);
  }

  @override
  void update(double dt) {
    super.update(dt);
    carSpawnTimer.update(dt);

    // Update grounds for infinite scrolling
    for (final ground in grounds) {
      ground.position.x -= speed * dt;

      // If ground is off-screen to the left, move it to the right
      if (ground.position.x < -ground.size.x) {
        ground.position.x += grounds.length * ground.size.x;
      }
    }

    // Update trees for infinite scrolling
    for (final tree in trees) {
      tree.position.x -= speed * dt;

      // If tree is off-screen to the left, move it to the right
      if (tree.position.x < -100) {
        tree.position.x += size.x + 800; // Reposition tree to the right
      }
    }
  }

  @override
  void onTap() {
    // bird.jump();
    bird.poop();
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (info.eventPosition.global.x >= size.x / 2) {
      bird.poop();
    }
  }

  void gameOver() {
    pauseEngine();
    overlays.add('GameOver');
  }

  void resumeGame() {
    // Reset bird
    bird.position = Vector2(size.x * 0.2, size.y * 0.3);
    bird.speedY = 0;

    // Clear cars
    for (final car in topLaneCars) {
      car.removeFromParent();
    }
    for (final car in bottomLaneCars) {
      car.removeFromParent();
    }
    topLaneCars.clear();
    bottomLaneCars.clear();

    // Reset background positions
    for (int i = 0; i < grounds.length; i++) {
      grounds[i].position = Vector2(i * size.x, size.y / 2);
    }

    for (int i = 0; i < trees.length; i++) {
      trees[i].position = Vector2(
        i * 300 + 200 + (i % 2) * 100,
        size.y - 100 - 150,
      );
    }

    // Restart the game
    carSpawnTimer.start();
    overlays.remove('GameOver');
    resumeEngine();
  }

// @override
// bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
//   if (event is RawKeyDownEvent) {
//     if (event.logicalKey == LogicalKeyboardKey.space) {
//       bird.jump();
//       return true;
//     }
//   }
//   return super.onKeyEvent(event, keysPressed);
// }
}
