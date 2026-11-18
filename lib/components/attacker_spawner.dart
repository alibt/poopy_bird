import 'package:flame/components.dart';

import '../game/poopy_bird_game.dart';
import 'road_attacker.dart';

/// Spawns curb-side attackers on high worlds when the bird is under pressure.
class AttackerSpawner extends Component with HasGameReference<PoopyBirdGame> {
  double _untilNext = 6;

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.attackersEnabled || !game.isRunning) return;
    _untilNext -= dt;
    if (_untilNext > 0) return;
    _untilNext = 4.5 + game.random.nextDouble() * 3.5;
    // More frequent when the bird is already being forced low.
    if (game.altitudePressure > 0.35) {
      _untilNext *= 0.7;
    }
    game.world.add(RoadAttacker(
      position: Vector2(game.size.x + 40, game.size.y - 4),
    ));
  }
}
