import 'package:flame/components.dart';

import '../game/config.dart';
import '../game/poopy_bird_game.dart';
import 'street.dart';
import 'tree.dart';

/// Scrolling background: the street and a repeating row of trees standing on
/// the far curb. Positions are derived from a single scroll offset, so nothing
/// drifts and everything follows screen resizes.
class Scenery extends Component with HasGameReference<PoopyBirdGame> {
  Scenery() : super(priority: 0);

  static const int _treeCount = 10;
  static const double _treeSpacing = 260;
  static const double _loopLength = _treeCount * _treeSpacing;

  final Street _street = Street();
  final List<Tree> _trees = [for (var i = 0; i < _treeCount; i++) Tree()];

  double _scroll = 0;

  @override
  Future<void> onLoad() async {
    addAll(_trees);
    add(_street);
    _layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _scroll += GameConfig.scrollSpeed * dt;
    _street.scrollOffset = _scroll;
    _layout();
  }

  void _layout() {
    for (var i = 0; i < _trees.length; i++) {
      // Alternate offsets so the row doesn't look perfectly regular.
      final base = i * _treeSpacing + (i.isOdd ? 90 : 0);
      final x = (base - _scroll) % _loopLength - _treeSpacing;
      _trees[i].position.setValues(x, game.roadTop);
    }
  }
}
