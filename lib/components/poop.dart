import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import 'car.dart';

class Poop extends CircleComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks {
  Poop({required Vector2 position})
      : super(
          radius: GameConfig.poopRadius,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0xFF6B4423),
          priority: 20,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += GameConfig.poopFallSpeed * dt;
    if (position.y - radius > game.size.y) removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // One poop lands on at most one car, even if it touches two at once.
    if (other is! Car || isRemoving) return;
    removeFromParent();
    if (other.splat()) game.onCarSplatted(other);
  }
}
