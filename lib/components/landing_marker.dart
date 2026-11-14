import 'dart:ui';

import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';

/// A shadow on the road straight below the bird, showing where a poop will
/// land. It shrinks and fades the higher the bird flies.
class LandingMarker extends Component with HasGameReference<PoopyBirdGame> {
  // Above the road, below cars.
  LandingMarker() : super(priority: 5);

  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    final ground = game.poopGroundY;
    final bird = game.bird.position;
    // 0 when the bird is at the top of the screen, 1 when it is on the road.
    final closeness = (bird.y / ground).clamp(0.0, 1.0);
    _paint.color = Color.fromRGBO(0, 0, 0, 0.15 + 0.25 * closeness);
    final width = 22 + 26 * closeness;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(bird.x, ground - 4),
          width: width,
          height: width * 0.3),
      _paint,
    );
  }
}
