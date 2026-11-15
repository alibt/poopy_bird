import 'dart:ui';

import 'package:flame/components.dart';

/// A poop splat, drawn on a car roof or the road. Placeholder art until the
/// Blender pipeline (M5) provides sprites.
class SplatMark extends PositionComponent {
  SplatMark({super.position, super.size, this.color = const Color(0xFF6B4423)})
      : super(anchor: Anchor.center);

  final Color color;

  /// 0 (invisible) to 1 (opaque).
  double opacity = 1;

  final Paint _brown = Paint();
  final Paint _highlight = Paint();

  @override
  void render(Canvas canvas) {
    _brown.color = color.withValues(alpha: opacity);
    _highlight.color = Color.fromRGBO(255, 255, 255, 0.4 * opacity);
    final w = size.x;
    final h = size.y;
    canvas.drawOval(Rect.fromLTWH(0, h * 0.2, w, h * 0.6), _brown);
    canvas.drawCircle(Offset(w * 0.2, h * 0.25), h * 0.25, _brown);
    canvas.drawCircle(Offset(w * 0.75, h * 0.3), h * 0.22, _brown);
    // Drips
    canvas.drawCircle(Offset(w * 0.3, h * 0.95), h * 0.12, _brown);
    canvas.drawCircle(Offset(w * 0.65, h * 1.05), h * 0.1, _brown);
    canvas.drawOval(
      Rect.fromLTWH(w * 0.3, h * 0.3, w * 0.25, h * 0.15),
      _highlight,
    );
  }
}
