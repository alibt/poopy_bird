import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import '../progress/level_result.dart';
import 'bird.dart';
import 'run_scoped.dart';

/// Roadside shooter on the near curb. Fires upward when the bird is low.
class RoadAttacker extends PositionComponent
    with HasGameReference<PoopyBirdGame>, RunScoped {
  RoadAttacker({required Vector2 position})
      : super(
          position: position,
          size: Vector2(36, 52),
          anchor: Anchor.bottomCenter,
          priority: 18,
        );

  static const double fireCooldown = 1.6;
  static const double aimRangeX = 160;

  double _untilFire = 0.4;

  static final Paint _body = Paint()..color = const Color(0xFF5D4037);
  static final Paint _shirt = Paint()..color = const Color(0xFFC62828);
  static final Paint _skin = Paint()..color = const Color(0xFFFFCC80);
  static final Paint _sling = Paint()
    ..color = const Color(0xFF37474F)
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  @override
  void update(double dt) {
    super.update(dt);
    if (isRemoving) return;
    position.x -= game.scrollSpeed * dt;
    _untilFire -= dt;
    if (_untilFire <= 0) {
      _untilFire = fireCooldown;
      _tryFire();
    }
    if (position.x < -size.x) removeFromParent();
  }

  void _tryFire() {
    if (!game.attackersEnabled || game.isFinished) return;
    final bird = game.bird;
    if (bird.position.y < game.attackerDangerY) return;
    if ((bird.position.x - position.x).abs() > aimRangeX) return;
    final target = bird.position.clone();
    final origin = position + Vector2(0, -size.y * 0.7);
    game.world.add(AttackerShot(position: origin, target: target));
  }

  @override
  void render(Canvas canvas) {
    // Simple readable silhouette — blender art can replace later.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.2, size.y * 0.35, size.x * 0.6, size.y * 0.55),
        const Radius.circular(6),
      ),
      _shirt,
    );
    canvas.drawCircle(Offset(size.x * 0.5, size.y * 0.22), 10, _skin);
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.35, size.y * 0.85, size.x * 0.12, size.y * 0.15),
      _body,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.55, size.y * 0.85, size.x * 0.12, size.y * 0.15),
      _body,
    );
    canvas.drawLine(
      Offset(size.x * 0.7, size.y * 0.45),
      Offset(size.x * 0.95, size.y * 0.25),
      _sling,
    );
  }
}

/// Projectile from a [RoadAttacker]. Hits the bird → crash.
class AttackerShot extends PositionComponent
    with HasGameReference<PoopyBirdGame>, CollisionCallbacks, RunScoped {
  AttackerShot({required Vector2 position, required Vector2 target})
      : super(
          position: position,
          size: Vector2.all(14),
          anchor: Anchor.center,
          priority: 35,
        ) {
    final delta = target - position;
    final len = max(1.0, delta.length);
    _velocity = delta / len * _speed;
  }

  static const double _speed = 280;
  late final Vector2 _velocity;

  static final Paint _paint = Paint()..color = const Color(0xFFFFEE58);
  static final Paint _core = Paint()..color = const Color(0xFFFF8F00);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    if (position.y < -20 ||
        position.x < -20 ||
        position.x > game.size.x + 40) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Bird) {
      game.finish(RunOutcome.crashed);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 7, _paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.5, _core);
  }
}
