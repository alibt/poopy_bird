import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import '../systems/belly.dart';
import 'car.dart';
import 'run_scoped.dart';

class Poop extends PositionComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks, RunScoped {
  Poop({
    required Vector2 position,
    this.kind = PoopKind.normal,
    this.velocityY = GameConfig.poopMinDropSpeed,
  }) : super(
          position: position,
          size: Vector2.all(_radiusFor(kind) * 2),
          anchor: Anchor.center,
          priority: 20,
        );

  static double _radiusFor(PoopKind kind) =>
      kind == PoopKind.big ? GameConfig.bigPoopRadius : GameConfig.poopRadius;

  late final Paint _body = Paint()..color = game.loadout.poopColor;
  static final Paint _shine = Paint()..color = const Color(0x55FFFFFF);

  final PoopKind kind;
  double velocityY;

  double get radius => size.x / 2;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isRemoving) return;
    velocityY += GameConfig.poopGravity * dt;
    position.y += velocityY * dt;

    // Reached the road without hitting a car.
    if (position.y >= game.poopGroundY) {
      removeFromParent();
      game.onPoopMissed(this);
    }
  }

  @override
  void render(Canvas canvas) {
    final r = radius;
    // A rough teardrop: round bottom, smaller top blob.
    canvas.drawCircle(Offset(r, r * 1.15), r * 0.85, _body);
    canvas.drawCircle(Offset(r, r * 0.55), r * 0.55, _body);
    canvas.drawCircle(Offset(r * 0.7, r * 0.9), r * 0.25, _shine);
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
    game.onPoopHitCar(this, other);
  }
}
