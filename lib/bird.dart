import 'package:flame/components.dart';
import 'package:poopy_bird/main.dart';

class Bird extends SpriteAnimationComponent with HasGameRef<BirdGame> {
  double speedY = 0;
  final double gravity = 10;
  final double jumpForce = -300;

  Bird({
    required SpriteAnimation animation,
    required Vector2 position,
  }) : super(
          animation: animation,
          position: position,
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
