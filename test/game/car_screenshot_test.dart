import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/components/car.dart';
import 'package:poopy_bird/game/poopy_bird_game.dart';
import 'package:poopy_bird/systems/car_type.dart';

/// Visual QA dump — parks car variants and writes an in-game PNG.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWithGame<PoopyBirdGame>(
    'dump in-game car lineup screenshot',
    () => PoopyBirdGame(random: Random(7)),
    (game) async {
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
      var x = 36.0;
      for (var i = 0; i < types.length; i++) {
        final lane = i.isEven ? 0 : 1;
        final t = types[i];
        await game.world.add(Car(
          type: t,
          lane: lane,
          speed: 0,
          position: Vector2(x, game.laneBaseline(lane)),
        ));
        x += t.width + 24;
      }
      await game.ready();
      for (var i = 0; i < 5; i++) {
        game.update(1 / 60);
        await game.ready();
      }

      final size = game.size;
      final recorder = PictureRecorder();
      game.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.x.toInt(), size.y.toInt());
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      final out = File('.artifacts/ingame_cars.png')
        ..createSync(recursive: true);
      await out.writeAsBytes(bytes!.buffer.asUint8List());
      expect(out.existsSync(), isTrue);
    },
  );
}
