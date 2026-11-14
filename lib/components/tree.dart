import 'dart:ui';

import 'package:flame/components.dart';

/// A roadside tree. Its position is the base of the trunk.
class Tree extends PositionComponent {
  Tree() : super(size: Vector2(80, 150), anchor: Anchor.bottomCenter);

  static final Paint _trunk = Paint()..color = const Color(0xFF8B4513);
  static final Paint _leaves = Paint()..color = const Color(0xFF228B22);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 10, size.y - 100, 20, 100),
      _trunk,
    );
    canvas.drawCircle(Offset(size.x / 2, size.y - 100), 40, _leaves);
  }
}
