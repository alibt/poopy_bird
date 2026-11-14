import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';

/// A horizontally repeating background strip that scrolls at a fraction of
/// the world speed. Subclasses draw one [loopWidth]-wide tile; this class
/// repeats it across the screen. Placeholder art until M5.
abstract class ParallaxStrip extends Component
    with HasGameReference<PoopyBirdGame> {
  ParallaxStrip(
      {required this.factor, required this.loopWidth, super.priority});

  /// 0 = fixed to the sky, 1 = moves with the road.
  final double factor;
  final double loopWidth;

  double scroll = 0;

  @override
  void render(Canvas canvas) {
    final offset = (scroll * factor) % loopWidth;
    for (var x = -offset; x < game.size.x; x += loopWidth) {
      canvas.save();
      canvas.translate(x, 0);
      renderTile(canvas);
      canvas.restore();
    }
  }

  void renderTile(Canvas canvas);
}

class CloudLayer extends ParallaxStrip {
  CloudLayer() : super(factor: 0.08, loopWidth: 1400, priority: -30);

  static final Paint _cloud = Paint()..color = const Color(0xDDFFFFFF);

  // (x, y as fraction of screen height, scale)
  static const List<(double, double, double)> _clouds = [
    (80, 0.10, 1.0),
    (420, 0.20, 0.7),
    (760, 0.08, 1.2),
    (1100, 0.17, 0.85),
  ];

  @override
  void renderTile(Canvas canvas) {
    for (final (x, yFraction, s) in _clouds) {
      final y = game.size.y * yFraction;
      canvas.drawOval(Rect.fromLTWH(x, y, 120 * s, 34 * s), _cloud);
      canvas.drawCircle(Offset(x + 40 * s, y + 4 * s), 24 * s, _cloud);
      canvas.drawCircle(Offset(x + 75 * s, y + 2 * s), 18 * s, _cloud);
    }
  }
}

/// A row of buildings standing on the road's far edge.
class SkylineLayer extends ParallaxStrip {
  SkylineLayer({
    required super.factor,
    required int seed,
    required Color color,
    required Color windowColor,
    required this.minHeight,
    required this.maxHeight,
    super.priority,
  })  : _body = Paint()..color = color,
        _window = Paint()..color = windowColor,
        super(loopWidth: 1200) {
    final random = Random(seed);
    var x = 0.0;
    while (x < loopWidth) {
      final width = 50 + random.nextDouble() * 70;
      _buildings.add((x, width, random.nextDouble()));
      x += width + random.nextDouble() * 20;
    }
  }

  /// Building heights as fractions of the sky's height (screen top to road).
  final double minHeight;
  final double maxHeight;

  final Paint _body;
  final Paint _window;

  /// (x, width, height roll 0..1)
  final List<(double, double, double)> _buildings = [];

  @override
  void renderTile(Canvas canvas) {
    final ground = game.roadTop;
    for (final (x, width, roll) in _buildings) {
      final height = ground * (minHeight + (maxHeight - minHeight) * roll);
      final top = ground - height;
      canvas.drawRect(Rect.fromLTWH(x, top, width, height), _body);
      for (var wy = top + 10; wy < ground - 16; wy += 18) {
        for (var wx = x + 8; wx < x + width - 12; wx += 16) {
          canvas.drawRect(Rect.fromLTWH(wx, wy, 7, 9), _window);
        }
      }
    }
  }
}
