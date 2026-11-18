import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/components/car.dart';
import 'package:poopy_bird/components/car_wash_truck.dart';
import 'package:poopy_bird/components/poop.dart';
import 'package:poopy_bird/game/poopy_bird_game.dart';
import 'package:poopy_bird/levels/level_definition.dart';
import 'package:poopy_bird/levels/run_plan.dart';
import 'package:poopy_bird/progress/level_result.dart';

const _frame = 1 / 60;

/// Steps the game frame by frame, letting newly added components (e.g.
/// spawned cars, whose sprites load asynchronously) finish mounting.
Future<void> _advance(PoopyBirdGame game, double seconds) async {
  for (var t = 0.0; t < seconds; t += _frame) {
    game.update(_frame);
    await game.ready();
  }
}

/// A short test level with no random traffic or food unless given.
LevelDefinition _level({
  List<Map<String, dynamic>> objectives = const [
    {'type': 'splatCars', 'count': 1},
  ],
  List<Map<String, dynamic>> traffic = const [],
  List<Map<String, dynamic>> scripted = const [],
  bool boss = false,
  double timeLimit = 3,
}) =>
    LevelDefinition.fromJson({
      'id': 'test_level',
      'version': 4,
      'name': 'Test',
      'timeLimit': timeLimit,
      'scrollSpeed': 120,
      'rageFillPerEscape': 0.1,
      'food': {'types': <String>[]},
      'traffic': traffic,
      'scriptedSpawns': scripted,
      'objectives': objectives,
      'stars': {'two': 100000, 'three': 200000},
      'isBoss': boss,
      'endWhenObjectivesMet': boss,
    });

/// A game for [level], already past its intro, that records results.
PoopyBirdGame Function() _gameFor(
  LevelDefinition level,
  List<LevelResult> results,
) =>
    () {
      final game = PoopyBirdGame(
        plan: LevelPlan(level),
        random: Random(7),
        onRunFinished: results.add,
      );
      return game;
    };

Future<Car> _parkCar(PoopyBirdGame game, {double x = 400, int lane = 1}) async {
  final car = Car(
    type: CarType.sedan,
    lane: lane,
    speed: 0,
    position: Vector2(x, game.laneBaseline(lane)),
  );
  await game.world.add(car);
  await game.ready();
  return car;
}

Future<void> _dropOn(PoopyBirdGame game, Car car) async {
  await game.world.add(Poop(position: car.roofCenter - Vector2(0, 25)));
  await game.ready();
  await _advance(game, 0.3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Level runs', () {
    final results = <LevelResult>[];
    setUp(results.clear);

    testWithGame<PoopyBirdGame>(
      'a level waits on its intro until started',
      _gameFor(_level(), results),
      (game) async {
        expect(game.started, isFalse);
        await _advance(game, 1);
        expect(game.elapsed, 0);
        game.startRun();
        await _advance(game, 1);
        expect(game.elapsed, greaterThan(0.9));
      },
    );

    testWithGame<PoopyBirdGame>(
      'meeting the objectives before time runs out wins with a star',
      _gameFor(_level(), results),
      (game) async {
        game.startRun();
        game.bird.removeFromParent();
        await _dropOn(game, await _parkCar(game));
        expect(game.isFinished, isFalse,
            reason: 'levels run until the time limit');
        await _advance(game, 3);

        expect(game.outcome, RunOutcome.won);
        expect(results, hasLength(1));
        final result = results.single;
        expect(result.levelId, 'test_level');
        expect(result.levelVersion, 4);
        expect(result.stars, 1);
        expect(result.carsSplatted, 1);
      },
    );

    testWithGame<PoopyBirdGame>(
      'time running out with objectives unmet is a loss',
      _gameFor(_level(), results),
      (game) async {
        game.startRun();
        game.bird.removeFromParent();
        await _advance(game, 3.2);
        expect(game.outcome, RunOutcome.timeUp);
        expect(results.single.stars, 0);
      },
    );

    testWithGame<PoopyBirdGame>(
      'too many escapes fails the level immediately',
      _gameFor(
        _level(objectives: [
          {'type': 'maxEscapes', 'count': 0},
        ], timeLimit: 30),
        results,
      ),
      (game) async {
        game.startRun();
        await _parkCar(game, x: -CarType.sedan.width - 1);
        game.update(_frame);
        game.update(_frame);
        expect(game.outcome, RunOutcome.objectiveFailed);
      },
    );

    testWithGame<PoopyBirdGame>(
      'random traffic follows the level segments and lanes',
      _gameFor(
        _level(traffic: [
          {
            'from': 1,
            'to': 3,
            'interval': 0.5,
            'groundSpeed': [0, 0],
            'cars': {'sportsCar': 1},
            'lanes': [0]
          },
        ]),
        results,
      ),
      (game) async {
        game.startRun();
        game.bird.removeFromParent();
        await _advance(game, 0.9);
        expect(game.world.children.whereType<Car>(), isEmpty);
        await _advance(game, 1);
        final cars = game.world.children.whereType<Car>().toList();
        expect(cars, isNotEmpty);
        expect(cars.every((c) => c.type == CarType.sportsCar && c.lane == 0),
            isTrue);
      },
    );

    testWithGame<PoopyBirdGame>(
      'restart replays the level from zero',
      _gameFor(_level(timeLimit: 10), results),
      (game) async {
        game.startRun();
        await _dropOn(game, await _parkCar(game));
        game.pause();
        expect(game.isPausedByPlayer, isTrue);
        game.restart();
        expect(game.isPausedByPlayer, isFalse);
        expect(game.elapsed, 0);
        expect(game.objectives.progressOf(0), 0);
        expect(game.started, isTrue);
      },
    );
  });

  group('Car wash boss', () {
    final results = <LevelResult>[];
    setUp(results.clear);

    final bossLevel = _level(
      boss: true,
      timeLimit: 60,
      objectives: [
        {'type': 'defeatBoss'},
      ],
      scripted: [
        {'at': 0.5, 'car': 'carWashTruck', 'lane': 1, 'groundSpeed': 0},
      ],
    );

    testWithGame<PoopyBirdGame>(
      'the truck arrives on schedule and takes 8 hits to defeat',
      _gameFor(bossLevel, results),
      (game) async {
        game.startRun();
        game.bird.removeFromParent();
        await _advance(game, 0.6);
        final truck = game.world.children.whereType<CarWashTruck>().single;
        truck.speed = 0;
        truck.position.x = 300;

        for (var i = 0; i < CarType.carWashTruck.hitPoints - 1; i++) {
          expect(truck.splat(), isTrue);
        }
        expect(truck.isSplatted, isFalse);
        expect(game.isFinished, isFalse);

        await _dropOn(game, truck);
        await _advance(game, 0.1);
        expect(truck.isSplatted, isTrue);
        expect(game.outcome, RunOutcome.won);
        expect(results.single.score, greaterThanOrEqualTo(1000));
      },
    );

    testWithGame<PoopyBirdGame>(
      'its spray washes nearby splatted cars clean',
      _gameFor(bossLevel, results),
      (game) async {
        game.startRun();
        game.bird.removeFromParent();
        await _advance(game, 0.6);
        final truck = game.world.children.whereType<CarWashTruck>().single
          ..speed = 0
          ..position.x = 300;
        final near = await _parkCar(game, x: 350, lane: 0)
          ..splat();
        final far = await _parkCar(game, x: 750, lane: 0)
          ..splat();

        expect(truck.spray(), 1);
        expect(near.isSplatted, isFalse);
        expect(far.isSplatted, isTrue);
      },
    );

    testWithGame<PoopyBirdGame>(
      'an undefeated truck loops back instead of escaping',
      _gameFor(bossLevel, results),
      (game) async {
        game.startRun();
        game.bird.removeFromParent();
        await _advance(game, 0.6);
        final truck = game.world.children.whereType<CarWashTruck>().single
          ..position.x = -CarType.carWashTruck.width + 1;
        await _advance(game, 0.1);
        expect(truck.isMounted, isTrue);
        expect(truck.position.x, greaterThan(game.size.x));
        expect(game.rage.value, 0);
      },
    );
  });
}
