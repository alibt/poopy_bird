import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import '../progress/level_result.dart';
import 'car.dart';
import 'food_pickup.dart';
import 'poop.dart';

class Bird extends PositionComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks {
  Bird({required SpriteAnimation animation, this.hue = 0})
      : _animation = animation,
        super(
          size: Vector2.all(GameConfig.birdSize),
          anchor: Anchor.center,
          priority: 30,
        );

  final SpriteAnimation _animation;
  final double hue;
  late final SpriteAnimationComponent _visual;

  /// Drawn sprite paint (cosmetics). Exposed for tests and tinting.
  Paint get paint => _visual.paint;

  double velocityY = 0;

  /// While true the bird poops whenever the cooldown allows.
  bool holdingPoop = false;

  /// Hold to dive under cruise for a risky, stronger drop.
  bool diving = false;

  double _sinceFlap = GameConfig.flapCooldown;
  double _sincePoop = double.infinity;

  /// Starts at cruise height — not up in the food band.
  Vector2 get spawnPoint => Vector2(game.size.x * 0.2, game.cruiseY);

  /// True once we've dropped meaningfully below cruise while diving.
  bool get isDiveBombing =>
      diving && position.y > game.cruiseY + GameConfig.diveEngagePadding;

  @override
  Future<void> onLoad() async {
    position = spawnPoint;
    // Artwork faces left; flip the visual only so hitboxes stay upright.
    _visual = SpriteAnimationComponent(
      animation: _animation,
      size: size.clone(),
      anchor: Anchor.center,
      position: size / 2,
      scale: Vector2(-1, 1),
    );
    if (hue != 0) {
      _visual.paint.colorFilter = hueRotation(hue);
    }
    add(_visual);
    add(CircleHitbox(
      radius: size.x * 0.34,
      position: Vector2(size.x * 0.5, size.y * 0.42),
      anchor: Anchor.center,
    ));
  }

  void reset() {
    position = spawnPoint;
    velocityY = 0;
    holdingPoop = false;
    diving = false;
    _sinceFlap = GameConfig.flapCooldown;
    _sincePoop = double.infinity;
    if (isLoaded) _visual.angle = 0;
  }

  /// Hop toward the food band. Cruise altitude is maintained without spam.
  void flap() {
    if (diving) return;
    if (_sinceFlap < GameConfig.flapCooldown) return;
    velocityY = GameConfig.flapVelocity;
    _sinceFlap = 0;
  }

  /// Drops a poop if the cooldown and belly allow it.
  Poop? poop() {
    if (_sincePoop < game.belly.cooldown) return null;
    final kind = game.belly.take();
    if (kind == null) {
      game.onBellyEmpty();
      return null;
    }
    _sincePoop = 0;
    game.stats.onPoopDropped();
    final dive = isDiveBombing;
    final drop = dive
        ? GameConfig.poopMaxDropSpeed
        : velocityY.clamp(
            GameConfig.poopMinDropSpeed,
            GameConfig.poopMaxDropSpeed,
          );
    final poop = Poop(
      position: position + Vector2(0, size.y * 0.3),
      kind: kind,
      velocityY: drop,
      diveBomb: dive,
    );
    game.world.add(poop);
    game.feedback.audio.sfx('poop.wav', volume: dive ? 0.9 : 0.7);
    if (dive) {
      game.feedback.hapticMedium();
    } else {
      game.feedback.hapticLight();
    }
    return poop;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceFlap += dt;
    _sincePoop += dt;

    velocityY += GameConfig.gravity * dt;

    final bob = sin(game.elapsed * GameConfig.cruiseBobHz * pi * 2) *
        GameConfig.cruiseBobAmplitude;
    final cruise = game.cruiseY + bob;

    if (diving) {
      // Pull hard toward the road — risk cars + attackers for power.
      velocityY += GameConfig.diveAccel * dt;
      velocityY = min(velocityY, GameConfig.diveMaxSpeed);
      _visual.angle = 0.35; // nose down
    } else {
      _visual.angle = 0;
      final settling = _sinceFlap >= GameConfig.flapHangTime;
      if (settling) {
        final delta = cruise - position.y;
        velocityY += delta.sign *
            min(delta.abs() * 4, GameConfig.cruiseSettle) *
            dt;
        velocityY *= pow(0.15, dt).toDouble();
      }
    }

    position.y += velocityY * dt;

    final top = game.foodBandTop;
    final bottom = min(game.size.y - size.y / 2, game.roadTop - size.y * 0.15);
    if (position.y < top) {
      position.y = top;
      velocityY = max(velocityY, 0);
    } else if (position.y > bottom) {
      position.y = bottom;
      velocityY = min(velocityY, 0);
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
