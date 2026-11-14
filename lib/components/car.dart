import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../game/poopy_bird_game.dart';
import 'run_scoped.dart';
import 'splat_mark.dart';

/// The kinds of car that can appear. New variants (convertible, bus, police…)
/// are added here.
enum CarType {
  sedan(bodyAsset: 'car-body.png', width: 80, height: 50);

  const CarType({
    required this.bodyAsset,
    required this.width,
    required this.height,
  });

  final String bodyAsset;
  final double width;

  /// Total height including the wheels.
  final double height;

  Vector2 get size => Vector2(width, height);
}

/// A car driving right-to-left along a lane. Its position is the bottom-left
/// corner, which sits on the lane's baseline.
class Car extends PositionComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks, RunScoped {
  Car({
    required this.type,
    required this.lane,
    required this.speed,
    required Vector2 position,
  }) : super(
          position: position,
          size: type.size,
          anchor: Anchor.bottomLeft,
          // Nearer lanes draw on top of farther ones.
          priority: 10 + lane,
        );

  static const double _tireDiameter = 20;

  final CarType type;
  final int lane;
  final double speed;

  bool isSplatted = false;

  final List<SpriteComponent> _tires = [];

  @override
  Future<void> onLoad() async {
    final bodySprite = await game.loadSprite(type.bodyAsset);
    final tireSprite = await game.loadSprite('tire.png');
    final bodyHeight = size.y - _tireDiameter / 2;

    // The artwork faces right but traffic drives left, so mirror the visuals.
    final visuals = PositionComponent(
      size: size,
      position: Vector2(size.x, 0),
      scale: Vector2(-1, 1),
    );
    visuals.add(SpriteComponent(
      sprite: bodySprite,
      size: Vector2(size.x, bodyHeight),
    ));
    for (final x in const [0.19, 0.775]) {
      final tire = SpriteComponent(
        sprite: tireSprite,
        size: Vector2.all(_tireDiameter),
        position: Vector2(size.x * x, bodyHeight),
        anchor: Anchor.center,
      );
      _tires.add(tire);
      visuals.add(tire);
    }
    add(visuals);
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  /// Centre of the roof, where splats land.
  Vector2 get roofCenter =>
      Vector2(position.x + size.x * 0.45, position.y - size.y);

  /// Marks the car as splatted. Returns false if it already was, so each car
  /// scores only once.
  bool splat() {
    if (isSplatted) return false;
    isSplatted = true;
    add(SplatMark(
      position: Vector2(size.x * 0.45, size.y * 0.12),
      size: Vector2(size.x * 0.4, size.y * 0.3),
    ));
    // Squash on impact. The car is anchored bottom-left, so it squashes
    // down onto its wheels.
    add(SequenceEffect([
      ScaleEffect.to(Vector2(1.12, 0.82), EffectController(duration: 0.07)),
      ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18)),
    ]));
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isRemoving) return;
    position.x -= speed * dt;

    // Roll the wheels to match ground speed. The visuals are mirrored, so a
    // positive angle here turns them counter-clockwise on screen.
    final roll = speed * dt / (_tireDiameter / 2);
    for (final tire in _tires) {
      tire.angle += roll;
    }

    if (position.x + size.x < 0) {
      if (!isSplatted) game.onCarEscaped(this);
      removeFromParent();
    }
  }
}
