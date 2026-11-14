import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/game/config.dart';
import 'package:poopy_bird/systems/belly.dart';
import 'package:poopy_bird/systems/food.dart';

void main() {
  group('Belly', () {
    test('starts full and runs out', () {
      final belly = Belly(capacity: 2);
      expect(belly.take(), PoopKind.normal);
      expect(belly.take(), PoopKind.normal);
      expect(belly.take(), isNull);
      expect(belly.isEmpty, isTrue);
    });

    test('digests one poop per interval up to capacity', () {
      final belly = Belly(capacity: 2, digestionInterval: 1)
        ..take()
        ..take();
      belly.update(0.5);
      expect(belly.ammo, 0);
      expect(belly.digestionProgress, closeTo(0.5, 1e-9));
      belly.update(0.5);
      expect(belly.ammo, 1);
      belly.update(5);
      expect(belly.ammo, 2);
    });

    test('berries refill ammo without exceeding capacity', () {
      final belly = Belly(capacity: 6);
      for (var i = 0; i < 5; i++) {
        belly.take();
      }
      belly.eat(FoodType.berries);
      expect(belly.ammo, 1 + GameConfig.berriesAmmo);
      belly.eat(FoodType.berries);
      expect(belly.ammo, 6);
    });

    test('chili gives free rapid fire for a limited time', () {
      final belly = Belly(capacity: 1)..take();
      belly.eat(FoodType.chili);
      expect(belly.cooldown, GameConfig.rapidFireCooldown);
      expect(belly.take(), PoopKind.normal);
      expect(belly.ammo, 0);
      belly.update(GameConfig.chiliDuration);
      expect(belly.isRapidFire, isFalse);
      expect(belly.cooldown, GameConfig.poopCooldown);
    });

    test('burrito big poops are used first', () {
      final belly = Belly()..eat(FoodType.burrito);
      for (var i = 0; i < GameConfig.burritoBigPoops; i++) {
        expect(belly.take(), PoopKind.big);
      }
      expect(belly.take(), PoopKind.normal);
      expect(belly.ammo, belly.capacity - 1);
    });
  });

  test('FoodType.pick covers every type in proportion to weight', () {
    expect(FoodType.pick(0), FoodType.berries);
    expect(FoodType.pick(0.65), FoodType.chili);
    expect(FoodType.pick(0.999), FoodType.burrito);
  });
}
