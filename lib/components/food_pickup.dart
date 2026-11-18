import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'run_scoped.dart';

/// Food floating in the air, scrolling with the world. Uses a short tumble
/// animation from the Blender pipeline (`food_<kind>_01..06.png`).
class FoodPickup extends PositionComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks, RunScoped {
  FoodPickup({required this.type, required Vector2 position})
      : _baseY = position.y,
        super(
          position: position,
          size: Vector2.all(40),
          anchor: Anchor.center,
          priority: 25,
        );

  final FoodType type;
  final double _baseY;
  double _age = 0;

  static const int frameCount = 6;

  static String frameAsset(FoodType type, int frame) {
    final kind = switch (type) {
      FoodType.berries => 'berries',
      FoodType.chili => 'chili',
      FoodType.burrito => 'burrito',
    };
    final i = ((frame - 1) % frameCount) + 1;
    return 'food_${kind}_${i.toString().padLeft(2, '0')}.png';
  }

  @override
  Future<void> onLoad() async {
    final frames = await Future.wait([
      for (var i = 1; i <= frameCount; i++) game.loadSprite(frameAsset(type, i)),
    ]);
    add(SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(frames, stepTime: 0.12),
      size: size.clone(),
    ));
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.x -= game.scrollSpeed * dt;
    position.y = _baseY + sin(_age * 3) * 6;
    if (position.x < -size.x) removeFromParent();
  }
}
