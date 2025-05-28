
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:poopy_bird/car.dart';
import 'package:poopy_bird/main.dart';
import 'package:poopy_bird/poop.dart';

class Bird extends SpriteAnimationComponent with HasGameRef<BirdGame>, CollisionCallbacks {
  double speedY = 0;
  final double gravity = 400; // More realistic gravity for Flame
  final double poopCooldown = 0.5;
  double timeSinceLastPoop = 0.0;
  bool isBeingDragged = false;

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
    speedY = -300;
  }

  void poop() {
    if (timeSinceLastPoop >= poopCooldown) {
      final poop = Poop(
        startPosition: position + Vector2(0, size.y / 2),
      );
      gameRef.add(poop);
      timeSinceLastPoop = 0.0;
    }
  }

  void startDragging() {
    isBeingDragged = true;
    speedY = 0;
  }

  void stopDragging() {
    isBeingDragged = false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    timeSinceLastPoop += dt;

    if (!isBeingDragged) {
      speedY += gravity * dt;
      position.y += speedY * dt;
    }

    // Optional: keep bird inside screen bounds
    position.clamp(
      Vector2.zero() + size / 2,
      gameRef.size - size / 2,
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Car) {
      gameRef.gameOver();
    }
    super.onCollision(intersectionPoints, other);
  }
}