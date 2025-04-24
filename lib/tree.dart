import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Tree extends PositionComponent {
  final Paint _trunkPaint = Paint()..color = const Color(0xFF8B4513); // Brown
  final Paint _leavesPaint = Paint()..color = const Color(0xFF228B22); // Forest green

  Tree({required Vector2 position})
      : super(
    position: position,
    size: Vector2(80, 150),
    anchor: Anchor.bottomCenter,
  );

  @override
  void render(Canvas canvas) {
    // Draw trunk
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 10, size.y - 100, 20, 100),
      _trunkPaint,
    );

    // Draw leaves (circular shape)
    canvas.drawCircle(
      Offset(size.x / 2, size.y - 100),
      40,
      _leavesPaint,
    );
  }
}
