import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:poopy_bird/poop.dart';

class Car extends PositionComponent with CollisionCallbacks {
  final double speed;
  final List<Car> laneList;
  final void Function()? onMissed;

  bool wasHit = false;
  bool _missedReported = false;

  late SpriteComponent body;
  late SpriteComponent frontTire;
  late SpriteComponent rearTire;

  Car({
    required Vector2 position,
    required Vector2 size,
    required this.laneList,
    this.speed = 120,
    Color color = Colors.red,
    this.onMissed,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    body = SpriteComponent()
      ..sprite = await Sprite.load('car-body.png')
      ..size = size
      ..position = Vector2.zero();
    add(body);

    final tireSprite = await Sprite.load('tire.png');

    frontTire = SpriteComponent()
      ..sprite = tireSprite
      ..size = Vector2(20, 20)
      ..position = Vector2(62, 40)
      ..anchor = Anchor.center;
    rearTire = SpriteComponent()
      ..sprite = tireSprite
      ..size = Vector2(20, 20)
      ..position = Vector2(15, 40)
      ..anchor = Anchor.center;

    add(frontTire);
    add(rearTire);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speed * dt;

    // Tire rotation based on speed
    final rotationAmount = speed * dt / 10;
    frontTire.angle -= rotationAmount;
    rearTire.angle -= rotationAmount;

    if (position.x + size.x < 0) {
      // Report a miss if car was never hit and we haven't reported yet
      if (!wasHit && !_missedReported) {
        _missedReported = true;
        onMissed?.call();
      }

      final lastCar = laneList.lastWhere((c) => c != this, orElse: () => this);
      final safeToReset = lastCar == this || lastCar.position.x < size.x - 250;

      if (safeToReset) {
        // Reset state for the recycled car
        wasHit = false;
        _missedReported = false;
        position.x = size.x + 100;
      } else {
        position.x = -size.x;
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Poop) {
      wasHit = true;
      body.removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
