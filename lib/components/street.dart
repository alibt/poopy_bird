import 'dart:ui';

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';

/// Procedural road — no tiled sprite (those seams looked like cracks).
class Street extends Component with HasGameReference<PoopyBirdGame> {
  Street() : super(priority: 0);

  static const double _dashLength = 32;
  static const double _dashGap = 20;

  static final Paint _asphalt = Paint()..color = const Color(0xFF3A4046);
  static final Paint _shoulder = Paint()..color = const Color(0xFF4A5158);
  static final Paint _curb = Paint()..color = const Color(0xFFB8BCC0);
  static final Paint _dash = Paint()
    ..color = const Color(0xFFFFD600)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

  double scrollOffset = 0;

  @override
  void render(Canvas canvas) {
    final top = game.roadTop;
    final width = game.size.x;
    final height = game.size.y - top;

    canvas.drawRect(Rect.fromLTWH(0, top, width, height), _asphalt);
    // Soft shoulders — no vertical seams.
    canvas.drawRect(Rect.fromLTWH(0, top, width, height * 0.08), _shoulder);
    canvas.drawRect(
      Rect.fromLTWH(0, game.size.y - height * 0.06, width, height * 0.06),
      _shoulder,
    );
    // Far curb under apartments.
    canvas.drawRect(Rect.fromLTWH(0, top - 4, width, 10), _curb);

    final baselines = GameConfig.laneBaselines;
    final mid = (baselines.first + baselines.last) / 2;
    final y = top + game.roadHeight * mid;
    const period = _dashLength + _dashGap;
    for (var x = -(scrollOffset % period); x < width; x += period) {
      canvas.drawLine(Offset(x, y), Offset(x + _dashLength, y), _dash);
    }
  }
}
