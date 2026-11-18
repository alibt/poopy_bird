import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';

/// A roadside tree. Its position is the base of the trunk.
class Tree extends SpriteComponent with HasGameReference<PoopyBirdGame> {
  Tree({this.variant = 1})
      : super(
          size: Vector2(90, 150),
          anchor: Anchor.bottomCenter,
          priority: 2,
        );

  /// 1–3 tree sprite variants from the Blender export.
  final int variant;

  @override
  Future<void> onLoad() async {
    final id = variant.clamp(1, 3).toString().padLeft(2, '0');
    sprite = await game.loadSprite('tree_$id.png');
  }
}
