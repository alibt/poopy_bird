import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/levels/level_definition.dart';

Map<String, dynamic> _validLevel() => {
      'id': 'test_1',
      'name': 'Test',
      'timeLimit': 30,
      'scrollSpeed': 120,
      'rageFillPerEscape': 0.2,
      'traffic': [
        {
          'from': 0,
          'to': 30,
          'interval': 2,
          'groundSpeed': [0, 50],
          'cars': {'sedan': 1}
        },
      ],
      'objectives': [
        {'type': 'splatCars', 'count': 3},
      ],
      'stars': {'two': 500, 'three': 900},
    };

void main() {
  test('parses a minimal level with defaults', () {
    final level = LevelDefinition.fromJson(_validLevel());
    expect(level.version, 1);
    expect(level.isBoss, isFalse);
    expect(level.traffic.single.lanes, [0, 1]);
    expect(level.food.types, isNotEmpty);
    expect(level.objectives.single.description, 'Splat 3 cars');
  });

  test('errors name the level and the problem', () {
    final missing = _validLevel()..remove('timeLimit');
    expect(
      () => LevelDefinition.fromJson(missing),
      throwsA(isA<FormatException>().having(
        (e) => e.message,
        'message',
        allOf(contains('test_1'), contains('timeLimit')),
      )),
    );

    final badCar = _validLevel();
    (badCar['traffic'] as List).first['cars'] = {'hovercar': 1};
    expect(() => LevelDefinition.fromJson(badCar), throwsFormatException);

    final badStars = _validLevel()..['stars'] = {'two': 900, 'three': 500};
    expect(() => LevelDefinition.fromJson(badStars), throwsFormatException);
  });

  test('stars: one for winning, more for score thresholds', () {
    const stars = StarThresholds(two: 500, three: 900);
    expect(stars.starsFor(won: false, score: 5000), 0);
    expect(stars.starsFor(won: true, score: 100), 1);
    expect(stars.starsFor(won: true, score: 500), 2);
    expect(stars.starsFor(won: true, score: 900), 3);
  });
}
