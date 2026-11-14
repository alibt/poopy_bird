import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/game/config.dart';
import 'package:poopy_bird/systems/difficulty.dart';

void main() {
  test('Difficulty ramps from start to end values and then holds', () {
    final difficulty = Difficulty(rampDuration: 100);
    expect(difficulty.scrollSpeed, GameConfig.scrollSpeedStart);
    expect(difficulty.carSpawnInterval, GameConfig.carSpawnIntervalStart);

    difficulty.update(50);
    expect(difficulty.progress, 0.5);
    expect(difficulty.scrollSpeed, greaterThan(GameConfig.scrollSpeedStart));
    expect(difficulty.carSpawnInterval,
        lessThan(GameConfig.carSpawnIntervalStart));

    difficulty.update(500);
    expect(difficulty.scrollSpeed, GameConfig.scrollSpeedEnd);
    expect(difficulty.carSpawnInterval, GameConfig.carSpawnIntervalEnd);
    expect(difficulty.carGroundSpeedMax, GameConfig.carGroundSpeedEnd);

    difficulty.reset();
    expect(difficulty.progress, 0);
  });
}
