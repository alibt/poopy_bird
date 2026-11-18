import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../game/poopy_bird_game.dart';
import '../systems/car_type.dart';
import 'run_scoped.dart';
import 'splat_mark.dart';

export '../systems/car_type.dart';

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
          size: Vector2(type.width, type.height),
          anchor: Anchor.bottomLeft,
          // Nearer lanes draw on top of farther ones.
          priority: 10 + lane,
        );

  final CarType type;
  final int lane;

  /// Screen speed, pixels per second to the left.
  double speed;

  /// Hits taken so far; the car is fully splatted at [CarType.hitPoints].
  int hitsTaken = 0;

  bool get isSplatted => hitsTaken >= type.hitPoints;

  final List<SplatMark> _marks = [];
  final List<SpriteComponent> _tires = [];
  double _tireDiameter = 24;

  /// Centre of the roof, where splats land.
  Vector2 get roofCenter =>
      Vector2(position.x + size.x * 0.45, position.y - size.y);

  double get centerX => position.x + size.x / 2;

  @override
  Future<void> onLoad() async {
    await buildVisuals();
    // Solid, so something entirely inside the car (e.g. after a long frame)
    // still counts as touching it, not just edge crossings.
    add(RectangleHitbox(collisionType: CollisionType.passive, isSolid: true));
  }

  /// Body sprite (arches cut out) + spinning tires with visible spokes.
  Future<void> buildVisuals() async {
    final bodySprite = await game.loadSprite(type.bodyAsset!);
    final visuals = PositionComponent(size: size);

    if (type.wheelsInSprite) {
      // Bosses keep baked wheels — too many axles to fake cleanly.
      visuals.add(SpriteComponent(sprite: bodySprite, size: size.clone()));
    } else {
      visuals.add(SpriteComponent(sprite: bodySprite, size: size.clone()));
      final tireSprite = await game.loadSprite('tire.png');
      _tireDiameter = size.y * 0.36;
      // Sit tires in the wheel arches (body faces left).
      for (final x in const [0.22, 0.78]) {
        final tire = SpriteComponent(
          sprite: tireSprite,
          size: Vector2.all(_tireDiameter),
          position: Vector2(size.x * x, size.y - _tireDiameter * 0.42),
          anchor: Anchor.center,
        );
        _tires.add(tire);
        visuals.add(tire);
      }
    }
    add(visuals);
  }

  /// Where the splat for the [hit]th hit goes, relative to the car.
  Vector2 splatPosition(int hit) => Vector2(size.x * 0.45, size.y * 0.12);

  /// Records a poop hit. Returns false if the car was already fully
  /// splatted, so it can't score again.
  bool splat() {
    if (isSplatted) return false;
    hitsTaken++;
    final mark = SplatMark(
      color: game.loadout.poopColor,
      position: splatPosition(hitsTaken),
      size: Vector2(min(size.x * 0.4, 40), min(size.y * 0.3, 18)),
    );
    _marks.add(mark);
    add(mark);
    // Squash on impact. The car is anchored bottom-left, so it squashes
    // down onto its wheels.
    add(SequenceEffect([
      ScaleEffect.to(Vector2(1.12, 0.82), EffectController(duration: 0.07)),
      ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.18)),
    ]));
    return true;
  }

  /// Washes every splat off, as if never hit.
  void clean() {
    hitsTaken = 0;
    for (final mark in _marks) {
      mark.removeFromParent();
    }
    _marks.clear();
  }

  static final Paint _hpBack = Paint()..color = const Color(0x88000000);
  static final Paint _hpFill = Paint()..color = const Color(0xFFFF5252);

  @override
  void update(double dt) {
    super.update(dt);
    if (isRemoving) return;
    position.x -= speed * dt;

    // Moving left → clockwise roll on screen (Flame angle increases clockwise).
    if (_tires.isNotEmpty && _tireDiameter > 0) {
      final roll = speed * dt / (_tireDiameter / 2);
      for (final tire in _tires) {
        tire.angle += roll;
      }
    }

    if (position.x + size.x < 0) onLeftScreen();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!type.isBoss || type.hitPoints <= 1) return;
    final remaining = 1 - hitsTaken / type.hitPoints;
    canvas.drawRect(Rect.fromLTWH(size.x * 0.2, -14, size.x * 0.6, 7), _hpBack);
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.2, -14, size.x * 0.6 * remaining, 7),
      _hpFill,
    );
  }

  /// Called once the car has fully left the screen on the left.
  void onLeftScreen() {
    if (!isSplatted) game.onCarEscaped(this);
    removeFromParent();
  }
}

/// A colour filter that rotates hues by [degrees], keeping alpha.
/// Used to make placeholder car variants from one sprite.
ColorFilter hueRotation(double degrees) {
  final r = degrees * pi / 180;
  final c = cos(r);
  final s = sin(r);
  const lr = 0.213, lg = 0.715, lb = 0.072;
  return ColorFilter.matrix([
    lr + c * (1 - lr) - s * lr, lg - c * lg - s * lg,
    lb - c * lb + s * (1 - lb), 0, 0, //
    lr - c * lr + s * 0.143, lg + c * (1 - lg) + s * 0.140,
    lb - c * lb - s * 0.283, 0, 0,
    lr - c * lr - s * (1 - lr), lg - c * lg + s * lg,
    lb + c * (1 - lb) + s * lb, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}
