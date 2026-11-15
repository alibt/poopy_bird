import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import '../progress/level_result.dart';
import 'car.dart';
import 'food_pickup.dart';
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

  /// While true the bird poops whenever the cooldown allows (finger or key
  /// held down).
  bool holdingPoop = false;

  double _sinceFlap = GameConfig.flapCooldown;
  double _sincePoop = double.infinity;

  Vector2 get spawnPoint => Vector2(game.size.x * 0.2, game.size.y * 0.3);

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
    holdingPoop = false;
    _sinceFlap = GameConfig.flapCooldown;
    _sincePoop = double.infinity;
  }

  void flap() {
    if (_sinceFlap < GameConfig.flapCooldown) return;
    velocityY = GameConfig.flapVelocity;
    _sinceFlap = 0;
  }

  /// Drops a poop if the cooldown and belly allow it. Returns the poop, or
  /// null.
  Poop? poop() {
    if (_sincePoop < game.belly.cooldown) return null;
    final kind = game.belly.take();
    if (kind == null) {
      game.onBellyEmpty();
      return null;
    }
    _sincePoop = 0;
    final poop = Poop(
      position: position + Vector2(0, size.y * 0.3),
      kind: kind,
      // A diving bird throws its poop harder.
      velocityY: velocityY.clamp(
        GameConfig.poopMinDropSpeed,
        GameConfig.poopMaxDropSpeed,
      ),
    );
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

    if (holdingPoop) poop();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Car) {
      game.finish(RunOutcome.crashed);
    } else if (other is FoodPickup) {
      game.onFoodEaten(other);
    }
  }
}
