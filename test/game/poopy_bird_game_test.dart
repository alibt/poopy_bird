import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/components/car.dart';
import 'package:poopy_bird/components/effects.dart';
import 'package:poopy_bird/components/food_pickup.dart';
import 'package:poopy_bird/components/poop.dart';
import 'package:poopy_bird/game/poopy_bird_game.dart';
import 'package:poopy_bird/systems/belly.dart';
import 'package:poopy_bird/systems/food.dart';
import 'package:poopy_bird/progress/level_result.dart';

const _frame = 1 / 60;

/// Creates a seeded Endless game.
PoopyBirdGame _createGame() => PoopyBirdGame(random: Random(42));

/// Steps the game frame by frame, letting newly added components (e.g.
/// spawned cars, whose sprites load asynchronously) finish mounting.
Future<void> _advance(PoopyBirdGame game, double seconds) async {
  for (var t = 0.0; t < seconds; t += _frame) {
    game.update(_frame);
    await game.ready();
  }
}

/// Adds a stationary car at [x] and waits for it to load.
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

/// Drops a poop just above [car]'s roof.
Future<void> _dropOn(
  PoopyBirdGame game,
  Car car, {
  PoopKind kind = PoopKind.normal,
}) async {
  await game.world.add(Poop(
    position: car.roofCenter - Vector2(0, 25),
    kind: kind,
  ));
  await game.ready();
  await _advance(game, 0.3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoopyBirdGame', () {
    testWithGame<PoopyBirdGame>(
      'distance score increases at 60fps',
      _createGame,
      (game) async {
        await _advance(game, 1);
        expect(game.score.score, greaterThanOrEqualTo(11));
      },
    );

    testWithGame<PoopyBirdGame>(
      'a car scores only once however many times it is hit',
      _createGame,
      (game) async {
        final car = await _parkCar(game);

        await _dropOn(game, car);
        expect(car.isSplatted, isTrue);
        expect(game.score.carsSplatted, 1);

        await _dropOn(game, car);
        expect(game.score.carsSplatted, 1);
        expect(game.world.children.whereType<Poop>(), isEmpty);
      },
    );

    testWithGame<PoopyBirdGame>(
      'clean cars that escape raise rage; five of them end the run',
      _createGame,
      (game) async {
        for (var i = 0; i < 5; i++) {
          final car = await _parkCar(game, x: -81);
          game.update(_frame);
          expect(car.isRemoving || car.isRemoved, isTrue);
        }
        expect(game.isFinished, isTrue);
        expect(game.outcome, RunOutcome.rageOut);
      },
    );

    testWithGame<PoopyBirdGame>(
      'splatted cars that escape do not raise rage',
      _createGame,
      (game) async {
        final car = await _parkCar(game, x: -81);
        car.splat();
        game.update(_frame);
        expect(game.rage.value, 0);
      },
    );

    testWithGame<PoopyBirdGame>(
      'crashing into a car ends the run and restart resets everything',
      _createGame,
      (game) async {
        await _advance(game, 0.5);
        final birdPos = game.bird.position;
        final car = Car(
          type: CarType.sedan,
          lane: 1,
          speed: 0,
          position: Vector2(birdPos.x - 40, birdPos.y + 25),
        );
        await game.world.add(car);
        await game.ready();
        game.update(_frame);

        expect(game.outcome, RunOutcome.crashed);
        expect(game.score.best, greaterThan(0));

        game.restart();
        await game.ready();
        expect(game.isFinished, isFalse);
        expect(game.score.score, 0);
        expect(game.rage.value, 0);
        expect(game.world.children.whereType<Car>(), isEmpty);
        expect(game.bird.position, game.bird.spawnPoint);
      },
    );

    testWithGame<PoopyBirdGame>(
      'consecutive splats build a combo multiplier',
      _createGame,
      (game) async {
        final first = await _parkCar(game, x: 300);
        final second = await _parkCar(game, x: 500);
        final before = game.score.score;
        await _dropOn(game, first);
        await _dropOn(game, second);
        expect(game.combo.count, 2);
        // 50 x1 + 50 x2, plus a little distance score.
        expect(game.score.score - before, inInclusiveRange(150, 160));
      },
    );

    testWithGame<PoopyBirdGame>(
      'a poop that hits the road breaks the combo and leaves a splat',
      _createGame,
      (game) async {
        final car = await _parkCar(game);
        await _dropOn(game, car);
        expect(game.combo.count, 1);

        await game.world
            .add(Poop(position: Vector2(700, game.poopGroundY - 30)));
        await game.ready();
        await _advance(game, 0.3);
        expect(game.combo.count, 0);
        expect(game.world.children.whereType<RoadSplat>(), isNotEmpty);
      },
    );

    testWithGame<PoopyBirdGame>(
      'a big poop splats nearby cars in both lanes',
      _createGame,
      (game) async {
        final near = await _parkCar(game, x: 400, lane: 1);
        final far = await _parkCar(game, x: 420, lane: 0);
        final distant = await _parkCar(game, x: 650, lane: 1);
        await _dropOn(game, far, kind: PoopKind.big);
        expect(near.isSplatted, isTrue);
        expect(far.isSplatted, isTrue);
        expect(distant.isSplatted, isFalse);
        expect(game.score.carsSplatted, 2);
      },
    );

    testWithGame<PoopyBirdGame>(
      'the bird cannot poop with an empty belly',
      _createGame,
      (game) async {
        while (game.belly.take() != null) {}
        expect(game.bird.poop(), isNull);
      },
    );

    testWithGame<PoopyBirdGame>(
      'flying into food eats it',
      _createGame,
      (game) async {
        while (game.belly.take() != null) {}
        await game.world.add(FoodPickup(
          type: FoodType.berries,
          position: game.bird.position.clone(),
        ));
        await game.ready();
        game.update(_frame);
        expect(game.belly.ammo, greaterThan(0));
        await _advance(game, 0.1);
        expect(game.world.children.whereType<FoodPickup>(), isEmpty);
      },
    );

    testWithGame<PoopyBirdGame>(
      'the world speeds up over a run and resets on restart',
      _createGame,
      (game) async {
        game.bird.removeFromParent();
        await game.ready();
        final start = game.scrollSpeed;
        await _advance(game, 30);
        expect(game.scrollSpeed, greaterThan(start));
        game.finish(RunOutcome.crashed);
        game.restart();
        expect(game.scrollSpeed, start);
      },
    );

    testWithGame<PoopyBirdGame>(
      'renders every element without errors through a busy run',
      _createGame,
      (game) async {
        final car = await _parkCar(game);
        game.belly.eat(FoodType.burrito);
        game.belly.eat(FoodType.chili);
        game.foodSpawner.spawn(FoodType.berries);
        game.foodSpawner.spawn(FoodType.chili);
        game.foodSpawner.spawn(FoodType.burrito);
        await _dropOn(game, car);
        await _dropOn(game, car, kind: PoopKind.big);
        await game.world
            .add(Poop(position: Vector2(700, game.poopGroundY - 5)));
        game.bird.holdingPoop = true;
        await game.ready();

        for (var i = 0; i < 120; i++) {
          game.update(_frame);
          await game.ready();
          final recorder = PictureRecorder();
          game.render(Canvas(recorder));
          recorder.endRecording();
        }
      },
    );

    testWithGame<PoopyBirdGame>(
      'traffic never overlaps within a lane and old cars are cleaned up',
      _createGame,
      (game) async {
        // Keep the bird out of the way so the run lasts.
        game.bird.removeFromParent();
        await game.ready();

        var maxCars = 0;
        for (var t = 0.0; t < 60; t += _frame) {
          game.update(_frame);
          await game.ready();
          final cars = game.world.children.whereType<Car>().toList();
          maxCars = max(maxCars, cars.length);
          for (final lane in [0, 1]) {
            final inLane = cars.where((c) => c.lane == lane).toList()
              ..sort((a, b) => a.position.x.compareTo(b.position.x));
            for (var i = 0; i + 1 < inLane.length; i++) {
              expect(
                inLane[i].position.x + inLane[i].size.x,
                lessThanOrEqualTo(inLane[i + 1].position.x),
                reason: 'cars overlap in lane $lane at t=$t',
              );
            }
          }
        }
        expect(maxCars, inInclusiveRange(3, 12),
            reason: "traffic should actually spawn, but stay bounded");
      },
    );
  });
}
