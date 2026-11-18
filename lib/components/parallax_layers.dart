import 'dart:ui';

import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';

/// A horizontally repeating background strip that scrolls at a fraction of
/// the world speed. Subclasses draw one [loopWidth]-wide tile; this class
/// repeats it across the screen.
abstract class ParallaxStrip extends Component
    with HasGameReference<PoopyBirdGame> {
  ParallaxStrip(
      {required this.factor, required this.loopWidth, super.priority});

  /// 0 = fixed to the sky, 1 = moves with the road.
  final double factor;
  double loopWidth;

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

/// Soft cloud plate from the Blender pipeline.
class CloudLayer extends ParallaxStrip {
  CloudLayer() : super(factor: 0.08, loopWidth: 1400, priority: -30);

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    _sprite = await game.loadSprite('bg_clouds.png');
  }

  @override
  void renderTile(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) return;
    final h = game.size.y * 0.35;
    sprite.render(canvas, size: Vector2(loopWidth, h));
  }
}

/// Skyline plate standing on the road's far edge.
/// Sized with the sprite's native aspect so buildings stay upright.
class SkylineLayer extends ParallaxStrip {
  SkylineLayer({
    required super.factor,
    required this.asset,
    required this.heightFraction,
    super.priority,
  }) : super(loopWidth: 1200);

  final String asset;
  final double heightFraction;
  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    _sprite = await game.loadSprite(asset);
  }

  @override
  void renderTile(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) return;
    final ground = game.roadTop;
    final height = ground * heightFraction;
    // Keep building proportions — don't squash into a fixed width.
    final aspect = sprite.srcSize.x / sprite.srcSize.y;
    final width = height * aspect;
    loopWidth = width;
    sprite.render(
      canvas,
      position: Vector2(0, ground - height + 6),
      size: Vector2(width, height),
    );
  }
}
