import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:poopy_bird/car.dart';
import 'package:poopy_bird/main.dart';

class Poop extends CircleComponent with HasGameRef<BirdGame>, CollisionCallbacks {
  final double fallSpeed = 200;

  Poop({
    required Vector2 startPosition,
  }) : super(
    radius: 10,
    position: startPosition,
    anchor: Anchor.center,
    paint: BasicPalette.brown.paint(), // Simple brown color
  );

  @override
  void update(double dt) {
    super.update(dt);

    position.y += fallSpeed * dt;

    // Remove when it falls off the screen
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Car) {
      // Handle poop hitting the car
      debugPrint('Poop hit a car!');
      removeFromParent(); // Remove poop after collision
    }
    super.onCollision(intersectionPoints, other);
  }
}