import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:poopy_bird/car.dart';
import 'package:poopy_bird/main.dart';
import 'package:poopy_bird/poop.dart';

class Bird extends SpriteAnimationComponent with HasGameReference<BirdGame>, CollisionCallbacks {
  double speedY = 0;
  final double gravity = 400;

  // Poop cooldown
  final double poopCooldown = 0.5;
  double _timeSinceLastPoop = 0.5;

  // Jump cooldown — prevents double-fire from onTapDown + onDragStart firing together
  final double jumpCooldown = 0.15;
  double _timeSinceLastJump = 0.15;

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
    if (_timeSinceLastJump >= jumpCooldown) {
      speedY = -300;
      _timeSinceLastJump = 0;
    }
  }

  void poop() {
    if (_timeSinceLastPoop >= poopCooldown) {
      final p = Poop(startPosition: position + Vector2(0, size.y / 2));
      game.add(p);
      _timeSinceLastPoop = 0;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    _timeSinceLastPoop += dt;
    _timeSinceLastJump += dt;

    // Gravity is always active — no more drag suspension
    speedY += gravity * dt;
    position.y += speedY * dt;

    position.clamp(
      Vector2.zero() + size / 2,
      game.size - size / 2,
    );
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Car) {
      game.gameOver();
    }
    super.onCollision(intersectionPoints, other);
  }
}
