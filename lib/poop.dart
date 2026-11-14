import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:poopy_bird/car.dart';
import 'package:poopy_bird/main.dart';

class Poop extends CircleComponent with HasGameReference<BirdGame>, CollisionCallbacks {
  final double fallSpeed = 200;

  Poop({required Vector2 startPosition})
      : super(
          radius: 10,
          position: startPosition,
          anchor: Anchor.center,
          paint: BasicPalette.brown.paint(),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;
    if (position.y > game.size.y) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Car) {
      game.onPoopHitCar();
      removeFromParent();
    }
    super.onCollision(intersectionPoints, other);
  }
}
