import 'dart:ui';

import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';

/// The road, drawn from the road top to the bottom of the screen, with a
/// dashed lane divider that scrolls by [scrollOffset].
class Street extends Component with HasGameReference<PoopyBirdGame> {
  Street() : super(priority: 0);

  static const double _dashLength = 20;
  static const double _dashGap = 15;
  static const double _curbHeight = 8;

  static final Paint _road = Paint()..color = const Color(0xFF2F4F4F);
  static final Paint _curb = Paint()..color = const Color(0xFFB0B0B0);
  static final Paint _dash = Paint()
    ..color = const Color(0xFFFFD600)
    ..strokeWidth = 4;

  double scrollOffset = 0;

  @override
  void render(Canvas canvas) {
    final top = game.roadTop;
    final width = game.size.x;
    canvas.drawRect(Rect.fromLTRB(0, top, width, game.size.y), _road);
    canvas.drawRect(Rect.fromLTWH(0, top, width, _curbHeight), _curb);

    final y = top + game.roadHeight * 0.5;
    const period = _dashLength + _dashGap;
    for (var x = -(scrollOffset % period); x < width; x += period) {
      canvas.drawLine(Offset(x, y), Offset(x + _dashLength, y), _dash);
    }
  }
}
