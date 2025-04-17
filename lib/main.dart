import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
  ).then((_) {
    runApp(
      GameWidget(
        game: BirdGame(),
      ),
    );
  });
}

class BirdGame extends FlameGame with TapDetector, KeyboardEvents {
  // Bird component
  late Bird bird;

  // Background components
  late List<Ground> grounds = [];
  late List<Tree> trees = [];

  // Game variables
  double speed = 120;

  @override
  Future<void> onLoad() async {
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

    // Add bird component to game
    bird = Bird(animation: birdAnimation);
    add(bird);

    // Initialize background - sky is the game background color
    // camera. = const Color(0xFF87CEEB); // Sky blue color

    // Add ground components for infinite scrolling
    for (int i = 0; i < 2; i++) {
      final ground = Ground(
        position: Vector2(i * size.x, size.y - 100),
        size: Vector2(size.x, 100),
      );
      grounds.add(ground);
      add(ground);
    }

    // Add some trees
    for (int i = 0; i < 8; i++) {
      final tree = Tree(
        position: Vector2(
          i * 300 + 200 + (i % 2) * 100,
          size.y - 100 - 150,
        ),
      );
      trees.add(tree);
      add(tree);
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

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
    bird.jump();
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

class Bird extends SpriteAnimationComponent with HasGameRef<BirdGame> {
  // Bird physics
  double speedY = 0;
  final double gravity = 10;
  final double jumpForce = -300;

  Bird({required SpriteAnimation animation})
      : super(
    animation: animation,
    position: Vector2(100, 200),
    size: Vector2(60, 60),
    anchor: Anchor.center,
  );

  void jump() {
    speedY = jumpForce;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    speedY += gravity;
    position.y += speedY * dt;

    // Simple bounds checking to keep bird on screen
    if (position.y > gameRef.size.y - 130) {
      position.y = gameRef.size.y - 130;
      speedY = 0;
    }

    if (position.y < 30) {
      position.y = 30;
      speedY = 0;
    }

    // Tilt the bird based on velocity
    angle = speedY * 0.003;
  }
}

class Ground extends PositionComponent {
  final Paint _paint = Paint()..color = const Color(0xFF8B4513); // Brown color

  Ground({required Vector2 position, required Vector2 size})
      : super(
    position: position,
    size: size,
  );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );
  }
}

class Tree extends PositionComponent {
  final Paint _trunkPaint = Paint()..color = const Color(0xFF8B4513); // Brown
  final Paint _leavesPaint = Paint()..color = const Color(0xFF228B22); // Forest green

  Tree({required Vector2 position})
      : super(
    position: position,
    size: Vector2(80, 150),
    anchor: Anchor.bottomCenter,
  );

  @override
  void render(Canvas canvas) {
    // Draw trunk
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 10, size.y - 100, 20, 100),
      _trunkPaint,
    );

    // Draw leaves (circular shape)
    canvas.drawCircle(
      Offset(size.x / 2, size.y - 100),
      40,
      _leavesPaint,
    );
  }
}