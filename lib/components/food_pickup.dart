import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'run_scoped.dart';

/// Food floating in the air, scrolling with the world. Uses a single sprite
/// with a smooth spin + bob (tumble frame sheets were too choppy at 6 frames).
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
  late final SpriteComponent _visual;

  static String assetFor(FoodType type) => switch (type) {
        FoodType.berries => 'food_berries.png',
        FoodType.chili => 'food_chili.png',
        FoodType.burrito => 'food_burrito.png',
      };

  @override
  Future<void> onLoad() async {
    _visual = SpriteComponent(
      sprite: await game.loadSprite(assetFor(type)),
      size: size.clone(),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_visual);
    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.x -= game.scrollSpeed * dt;
    position.y = _baseY + sin(_age * 2.4) * 10;
    _visual.angle = _age * 1.8;
    final pulse = 1 + sin(_age * 3.1) * 0.07;
    _visual.scale.setValues(pulse, pulse);
    if (position.x < -size.x) removeFromParent();
  }
}
