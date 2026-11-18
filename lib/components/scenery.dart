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
  final List<Tree> _trees = [
    for (var i = 0; i < _treeCount; i++) Tree(variant: (i % 3) + 1),
  ];
  late final List<ParallaxStrip> _layers = [
    CloudLayer(),
    SkylineLayer(
      factor: 0.2,
      asset: 'bg_skyline_far.png',
      heightFraction: 0.72,
      priority: -20,
    ),
    SkylineLayer(
      factor: 0.5,
      asset: 'bg_skyline_near.png',
      heightFraction: 0.48,
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
      final base = i * _treeSpacing + (i.isOdd ? 60 : 0);
      final x = (base - _scroll) % _loopLength - _treeSpacing;
      // Plant trees on the far curb (slightly into the road top).
      _trees[i].position.setValues(x, game.roadTop + 6);
    }
  }
}
