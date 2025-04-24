import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Street extends PositionComponent {
  final Paint _roadPaint = Paint()..color = const Color(0xFF2F4F4F);
  final Paint _linePaint = Paint()
    ..color = Colors.yellow
    ..strokeWidth = 4;

  Street({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _roadPaint,
    );

    const dashWidth = 20;
    const dashSpace = 15;
    double x = 0;

    while (x < size.x) {
      canvas.drawLine(
        Offset(x, size.y / 2),
        Offset(x + dashWidth, size.y / 2),
        _linePaint,
      );
      x += dashWidth + dashSpace;
    }
  }
}
