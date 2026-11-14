import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import 'car.dart';
import 'poop.dart';

class Bird extends SpriteAnimationComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks {
  Bird({required super.animation})
      : super(
          size: Vector2.all(GameConfig.birdSize),
          anchor: Anchor.center,
          priority: 30,
        );

  double velocityY = 0;
  double _sinceFlap = GameConfig.flapCooldown;
  double _sincePoop = GameConfig.poopCooldown;

  Vector2 get spawnPoint => Vector2(game.size.x * 0.2, game.size.y * 0.3);

  bool get canPoop => _sincePoop >= GameConfig.poopCooldown;

  @override
  Future<void> onLoad() async {
    position = spawnPoint;
    // The artwork has empty space under the feet; keep the hitbox on the body
    // so near-misses feel fair.
    add(CircleHitbox(
      radius: size.x * 0.34,
      position: Vector2(size.x * 0.52, size.y * 0.38),
      anchor: Anchor.center,
    ));
  }

  void reset() {
    position = spawnPoint;
    velocityY = 0;
    _sinceFlap = GameConfig.flapCooldown;
    _sincePoop = GameConfig.poopCooldown;
  }

  void flap() {
    if (_sinceFlap < GameConfig.flapCooldown) return;
    velocityY = GameConfig.flapVelocity;
    _sinceFlap = 0;
  }

  /// Drops a poop if the cooldown allows it. Returns the poop, or null.
  Poop? poop() {
    if (!canPoop) return null;
    _sincePoop = 0;
    final poop = Poop(position: position + Vector2(0, size.y * 0.3));
    game.world.add(poop);
    return poop;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceFlap += dt;
    _sincePoop += dt;

    velocityY += GameConfig.gravity * dt;
    position.y += velocityY * dt;

    // Stop at the screen edges instead of building up speed against them.
    final top = size.y / 2;
    final bottom = game.size.y - size.y / 2;
    if (position.y < top) {
      position.y = top;
      velocityY = max(velocityY, 0);
    } else if (position.y > bottom) {
      position.y = bottom;
      velocityY = 0;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Car) game.gameOver(GameOverReason.crash);
  }
}
