import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/components/car.dart';
import 'package:poopy_bird/components/poop.dart';
import 'package:poopy_bird/game/config.dart';
import 'package:poopy_bird/game/poopy_bird_game.dart';
import 'package:poopy_bird/systems/car_type.dart';
import 'package:poopy_bird/systems/food.dart';

const _frame = 1 / 60;

Future<void> _dump(PoopyBirdGame game, String name) async {
  final size = game.size;
  final recorder = PictureRecorder();
  game.render(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.x.toInt(), size.y.toInt());
  final bytes = await image.toByteData(format: ImageByteFormat.png);
  final out = File('.artifacts/$name.png')..createSync(recursive: true);
  await out.writeAsBytes(bytes!.buffer.asUint8List());
  expect(out.existsSync(), isTrue);
}

Future<void> _tick(PoopyBirdGame game, int frames) async {
  for (var i = 0; i < frames; i++) {
    game.update(_frame);
    await game.ready();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame<PoopyBirdGame>(
    'dive-bomb engages below cruise and marks poops',
    () => PoopyBirdGame(random: Random(3)),
    (game) async {
      game.belly.eat(FoodType.berries);
      final startY = game.bird.position.y;
      expect(startY, closeTo(game.cruiseY, GameConfig.cruiseBobAmplitude + 2));

      game.bird.diving = true;
      await _tick(game, 45);
      expect(game.bird.position.y, greaterThan(startY + GameConfig.diveEngagePadding));
      expect(game.bird.isDiveBombing, isTrue);

      final poop = game.bird.poop();
      expect(poop, isNotNull);
      expect(poop!.diveBomb, isTrue);
      expect(poop.velocityY, GameConfig.poopMaxDropSpeed);
    },
  );

  testWithGame<PoopyBirdGame>(
    'dump playfeel screenshots (cars, street, skyline, bird)',
    () => PoopyBirdGame(random: Random(11)),
    (game) async {
      // Phone-ish portrait canvas.
      game.onGameResize(Vector2(720, 1280));
      await game.ready();

      for (final c in game.world.children.whereType<Car>().toList()) {
        c.removeFromParent();
      }
      await game.ready();

      const types = [
        CarType.sedan,
        CarType.taxi,
        CarType.sportsCar,
        CarType.police,
        CarType.bus,
      ];
      var x = 48.0;
      for (var i = 0; i < types.length; i++) {
        final lane = i.isEven ? 0 : 1;
        final t = types[i];
        await game.world.add(Car(
          type: t,
          lane: lane,
          speed: 0,
          position: Vector2(x, game.laneBaseline(lane)),
        ));
        x += t.width + 20;
      }
      await _tick(game, 8);
      await _dump(game, 'qa_full_scene');

      // Dive pose for bird.
      game.bird.diving = true;
      await _tick(game, 40);
      await _dump(game, 'qa_dive_pose');

      // Cruise-only plate (bird up, no dive).
      game.bird.diving = false;
      game.bird.position.y = game.cruiseY;
      game.bird.velocityY = 0;
      await _tick(game, 5);
      await _dump(game, 'qa_cruise_pose');
    },
  );
}
