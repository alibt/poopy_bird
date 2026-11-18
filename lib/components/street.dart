import 'dart:ui';

import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';

/// The road: Blender asphalt strip plus dashed lane divider overlays.
class Street extends Component with HasGameReference<PoopyBirdGame> {
  Street() : super(priority: 0);

  static const double _dashLength = 28;
  static const double _dashGap = 18;
  static const double _loopWidth = 1200;

  static final Paint _fallback = Paint()..color = const Color(0xFF2A3034);
  static final Paint _curb = Paint()..color = const Color(0xFFB0B0B0);
  static final Paint _dash = Paint()
    ..color = const Color(0xFFFFD600)
    ..strokeWidth = 5;

  double scrollOffset = 0;
  Sprite? _strip;

  @override
  Future<void> onLoad() async {
    _strip = await game.loadSprite('bg_street.png');
  }

  @override
  void render(Canvas canvas) {
    final top = game.roadTop;
    final width = game.size.x;
    final height = game.size.y - top;
    final strip = _strip;
    if (strip != null) {
      final offset = scrollOffset % _loopWidth;
      for (var x = -offset; x < width; x += _loopWidth) {
        strip.render(
          canvas,
          position: Vector2(x, top),
          size: Vector2(_loopWidth, height),
        );
      }
    } else {
      canvas.drawRect(Rect.fromLTWH(0, top, width, height), _fallback);
    }
    // Far curb under the apartments — keeps skyline visually planted.
    canvas.drawRect(Rect.fromLTWH(0, top - 4, width, 10), _curb);

    final baselines = GameConfig.laneBaselines;
    for (var i = 0; i < baselines.length - 1; i++) {
      final y = top + game.roadHeight * ((baselines[i] + baselines[i + 1]) / 2);
      const period = _dashLength + _dashGap;
      for (var x = -(scrollOffset % period); x < width; x += period) {
        canvas.drawLine(Offset(x, y), Offset(x + _dashLength, y), _dash);
      }
    }
  }
}
