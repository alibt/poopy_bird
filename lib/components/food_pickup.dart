import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import '../systems/food.dart';
import 'run_scoped.dart';

/// Food floating in the air, scrolling with the world. Placeholder art until
/// the Blender pipeline (M5).
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

  static final Paint _berry = Paint()..color = const Color(0xFF6A1B9A);
  static final Paint _leaf = Paint()..color = const Color(0xFF2E7D32);
  static final Paint _chili = Paint()..color = const Color(0xFFD32F2F);
  static final Paint _tortilla = Paint()..color = const Color(0xFFE6C27A);
  static final Paint _filling = Paint()..color = const Color(0xFF8D6E63);
  static final Paint _glow = Paint()..color = const Color(0x55FFFFFF);
  static final Paint _stroke = Paint()
    ..color = const Color(0xFF000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
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

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c, size.x / 2, _glow);
    switch (type) {
      case FoodType.berries:
        for (final o in const [Offset(-6, 3), Offset(6, 3), Offset(0, -6)]) {
          canvas.drawCircle(c + o, 7, _berry);
          canvas.drawCircle(c + o, 7, _stroke);
        }
        canvas.drawOval(
            Rect.fromCenter(
                center: c + const Offset(4, -13), width: 10, height: 5),
            _leaf);
      case FoodType.chili:
        final body = Path()
          ..moveTo(c.dx - 12, c.dy - 8)
          ..quadraticBezierTo(c.dx + 14, c.dy - 6, c.dx + 10, c.dy + 14)
          ..quadraticBezierTo(c.dx + 2, c.dy + 2, c.dx - 12, c.dy - 2)
          ..close();
        canvas.drawPath(body, _chili);
        canvas.drawPath(body, _stroke);
        canvas.drawCircle(c + const Offset(-13, -6), 4, _leaf);
      case FoodType.burrito:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 30, height: 18),
          const Radius.circular(9),
        );
        canvas.drawRRect(rect, _tortilla);
        canvas.drawCircle(c + const Offset(12, 0), 6, _filling);
        canvas.drawRRect(rect, _stroke);
    }
  }
}
