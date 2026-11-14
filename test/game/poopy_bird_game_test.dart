import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/components/car.dart';
import 'package:poopy_bird/components/poop.dart';
import 'package:poopy_bird/game/poopy_bird_game.dart';
import 'package:poopy_bird/ui/game_over_overlay.dart';

const _frame = 1 / 60;

/// Creates a seeded game with its overlays registered, as GameWidget would.
PoopyBirdGame _createGame() {
  final game = PoopyBirdGame(random: Random(42));
  game.overlays.addEntry(GameOverOverlay.id, (_, __) => const SizedBox());
  return game;
}

void _advance(PoopyBirdGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += _frame) {
    game.update(_frame);
  }
}

/// Adds a stationary car in the near lane at [x] and waits for it to load.
Future<Car> _parkCar(PoopyBirdGame game, {double x = 400}) async {
  final car = Car(
    type: CarType.sedan,
    lane: 1,
    speed: 0,
    position: Vector2(x, game.laneBaseline(1)),
  );
  await game.world.add(car);
  await game.ready();
  return car;
}

/// Drops a poop just above [car]'s roof.
Future<void> _dropOn(PoopyBirdGame game, Car car) async {
  await game.world.add(Poop(
    position: Vector2(car.position.x + car.size.x / 2, car.position.y - car.size.y - 20),
  ));
  await game.ready();
  _advance(game, 0.3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoopyBirdGame', () {
    testWithGame<PoopyBirdGame>(
      'distance score increases at 60fps',
      _createGame,
      (game) async {
        _advance(game, 1);
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
        expect(game.isGameOver, isTrue);
        expect(game.gameOverReason, GameOverReason.rage);
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
        _advance(game, 0.5);
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

        expect(game.gameOverReason, GameOverReason.crash);
        expect(game.score.best, greaterThan(0));

        game.restart();
        await game.ready();
        expect(game.isGameOver, isFalse);
        expect(game.score.score, 0);
        expect(game.rage.value, 0);
        expect(game.world.children.whereType<Car>(), isEmpty);
        expect(game.bird.position, game.bird.spawnPoint);
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
        expect(maxCars, lessThan(12));
      },
    );
  });
}
