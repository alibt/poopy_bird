import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Car extends PositionComponent {
  final double speed;
  final List<Car> laneList;

  late SpriteComponent body;
  late SpriteComponent frontTire;
  late SpriteComponent rearTire;

  Car({
    required Vector2 position,
    required Vector2 size,
    required this.laneList,
    this.speed = 120,
    Color color = Colors.red,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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

    if (position.x + size.x < 0) {
      final lastCar = laneList.lastWhere((c) => c != this, orElse: () => this);

      final safeToReset = lastCar == this || lastCar.position.x < size.x - 250;

      if (safeToReset) {
        position.x = size.x + 100;
      } else {
        position.x = -size.x;
      }
    }

    final rotationAmount = speed * dt / 10;
    frontTire.angle -= rotationAmount;
    rearTire.angle -= rotationAmount;
  }
}
