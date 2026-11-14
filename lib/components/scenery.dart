import 'dart:ui';

import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import 'parallax_layers.dart';
import 'street.dart';
import 'tree.dart';

/// Scrolling background: parallax clouds and buildings, a row of trees on
/// the far curb, and the street. Everything is positioned from one scroll
/// offset, so nothing drifts and it all follows screen resizes.
class Scenery extends Component with HasGameReference<PoopyBirdGame> {
  Scenery() : super(priority: 0);

  static const int _treeCount = 10;
  static const double _treeSpacing = 260;
  static const double _loopLength = _treeCount * _treeSpacing;

  final Street _street = Street();
  final List<Tree> _trees = [for (var i = 0; i < _treeCount; i++) Tree()];
  late final List<ParallaxStrip> _layers = [
    CloudLayer(),
    SkylineLayer(
      factor: 0.2,
      seed: 1,
      color: const Color(0xFFB3CDE0),
      windowColor: const Color(0xFFCFE0EC),
      minHeight: 0.35,
      maxHeight: 0.7,
      priority: -20,
    ),
    SkylineLayer(
      factor: 0.5,
      seed: 2,
      color: const Color(0xFF7F9DB5),
      windowColor: const Color(0xFFF3E9A6),
      minHeight: 0.2,
      maxHeight: 0.45,
      priority: -10,
    ),
  ];

  double _scroll = 0;

  @override
  Future<void> onLoad() async {
    addAll(_layers);
    addAll(_trees);
    add(_street);
    _layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _scroll += game.scrollSpeed * dt;
    _street.scrollOffset = _scroll;
    for (final layer in _layers) {
      layer.scroll = _scroll;
    }
    _layout();
  }

  void _layout() {
    for (var i = 0; i < _trees.length; i++) {
      // Alternate offsets so the row doesn't look perfectly regular.
      final base = i * _treeSpacing + (i.isOdd ? 60 : 0);
      final x = (base - _scroll) % _loopLength - _treeSpacing;
      _trees[i].position.setValues(x, game.roadTop);
    }
  }
}
