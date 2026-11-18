import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'run_scoped.dart';

/// Food floating in the air, scrolling with the world.
class FoodPickup extends PositionComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks, RunScoped {
  FoodPickup({required this.type, required Vector2 position})
      : _baseY = position.y,
        super(
          position: position,
          size: Vector2.all(36),
          anchor: Anchor.center,
          priority: 25,
        );

  final FoodType type;
  final double _baseY;
  double _age = 0;

  static String assetFor(FoodType type) => switch (type) {
        FoodType.berries => 'food_berries.png',
        FoodType.chili => 'food_chili.png',
        FoodType.burrito => 'food_burrito.png',
      };

  @override
  Future<void> onLoad() async {
    add(SpriteComponent(
      sprite: await game.loadSprite(assetFor(type)),
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
