import 'dart:math';

import '../game/config.dart';
import 'food.dart';

enum PoopKind { normal, big }

/// The bird's ammo. Each poop uses one; the belly slowly digests more, and
/// food tops it up or grants special poops.
class Belly {
  Belly({
    this.capacity = GameConfig.bellyCapacity,
    this.digestionInterval = GameConfig.digestionInterval,
    this.chiliDuration = GameConfig.chiliDuration,
    this.burritoBigPoops = GameConfig.burritoBigPoops,
  }) : ammo = capacity;

  final int capacity;
  final double digestionInterval;
  final double chiliDuration;
  final int burritoBigPoops;

  int ammo;
  int bigPoopsLeft = 0;
  double rapidFireLeft = 0;
  double _digested = 0;

  bool get isRapidFire => rapidFireLeft > 0;

  bool get isEmpty => ammo == 0 && bigPoopsLeft == 0 && !isRapidFire;

  /// Progress toward the next digested poop, 0 to 1.
  double get digestionProgress =>
      ammo >= capacity ? 0 : _digested / digestionInterval;

  /// Seconds the bird must wait between poops right now.
  double get cooldown =>
      isRapidFire ? GameConfig.rapidFireCooldown : GameConfig.poopCooldown;

  /// Takes one poop out of the belly, or returns null if there is none.
  /// Big poops are used first; rapid fire costs no ammo.
  PoopKind? take() {
    if (bigPoopsLeft > 0) {
      bigPoopsLeft--;
      return PoopKind.big;
    }
    if (isRapidFire) return PoopKind.normal;
    if (ammo == 0) return null;
    ammo--;
    return PoopKind.normal;
  }

  void eat(FoodType food) {
    switch (food) {
      case FoodType.berries:
        ammo = min(capacity, ammo + GameConfig.berriesAmmo);
      case FoodType.chili:
        rapidFireLeft = chiliDuration;
      case FoodType.burrito:
        bigPoopsLeft += burritoBigPoops;
    }
  }

  void update(double dt) {
    rapidFireLeft = max(0, rapidFireLeft - dt);
    if (ammo >= capacity) {
      _digested = 0;
      return;
    }
    _digested += dt;
    if (_digested >= digestionInterval) {
      _digested -= digestionInterval;
      ammo++;
    }
  }

  void reset() {
    ammo = capacity;
    bigPoopsLeft = 0;
    rapidFireLeft = 0;
    _digested = 0;
  }
}
