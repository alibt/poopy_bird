import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

import 'car.dart';
import 'effects.dart';

/// World 1 boss. A big, slow truck that takes [CarType.hitPoints] poops.
/// Every few seconds it sprays water that washes nearby cars clean, so they
/// count as escapes again. If it drives off-screen undefeated it loops back
/// around (in Endless, only once more).
class CarWashTruck extends Car {
  CarWashTruck({
    required super.lane,
    required super.speed,
    required super.position,
  }) : super(type: CarType.carWashTruck);

  static const double sprayInterval = 4;
  static const double sprayReach = 220;

  /// How far off the right edge it re-enters after driving off.
  static const double _reentryGap = 160;

  double _untilSpray = sprayInterval;

  static final Paint _hpBack = Paint()..color = const Color(0x88000000);
  static final Paint _hpFill = Paint()..color = const Color(0xFFFF5252);

  @override
  Vector2 splatPosition(int hit) {
    // Spread the splats along the tank roof.
    final t = (hit - 1) / max(1, type.hitPoints - 1);
    return Vector2(size.x * (0.4 + 0.5 * t), size.y * 0.1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isSplatted || isRemoving) return;
    _untilSpray -= dt;
    if (_untilSpray <= 0) {
      _untilSpray = sprayInterval;
      spray();
    }
  }

  /// Washes splatted cars within [sprayReach]. Returns how many were washed.
  int spray() {
    final washed = game.world.children
        .whereType<Car>()
        .where((c) =>
            c != this &&
            c.hitsTaken > 0 &&
            (c.centerX - centerX).abs() <= sprayReach)
        .toList();
    for (final car in washed) {
      car.clean();
    }
    game.world.add(_waterBurst());
    if (washed.isNotEmpty) {
      game.world.add(FloatingText(
        washed.length == 1 ? 'Washed!' : 'Washed x${washed.length}!',
        position: Vector2(centerX, position.y - size.y - 30),
        color: const Color(0xFF4FC3F7),
      ));
    }
    return washed.length;
  }

  ParticleSystemComponent _waterBurst() {
    final random = game.random;
    final paint = Paint()..color = const Color(0xCC4FC3F7);
    return ParticleSystemComponent(
      position: Vector2(position.x + size.x * 0.6, position.y - size.y),
      priority: 40,
      particle: Particle.generate(
        count: 40,
        lifespan: 0.9,
        generator: (_) {
          final angle = -pi * random.nextDouble();
          final v = 120 + random.nextDouble() * 180;
          return AcceleratedParticle(
            acceleration: Vector2(0, 500),
            speed: Vector2(cos(angle) * v * 1.4, sin(angle) * v),
            child: CircleParticle(
                radius: 2 + random.nextDouble() * 2, paint: paint),
          );
        },
      ),
    );
  }

  /// In Endless the truck gives up after this many passes, so visits can't
  /// pile up. In a boss level it keeps coming until defeated.
  static const int endlessMaxPasses = 2;

  int _passes = 0;

  @override
  void onLeftScreen() {
    _passes++;
    if (isSplatted) {
      removeFromParent();
    } else if (game.plan.level == null && _passes >= endlessMaxPasses) {
      super.onLeftScreen();
    } else {
      // Undefeated: come around again.
      position.x = game.size.x + _reentryGap;
    }
  }

  @override
  void render(Canvas canvas) {
    // Sprite body comes from [Car.buildVisuals]; draw the health bar above.
    final w = size.x;
    final remaining = 1 - hitsTaken / type.hitPoints;
    canvas.drawRect(Rect.fromLTWH(w * 0.2, -14, w * 0.6, 7), _hpBack);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.2, -14, w * 0.6 * remaining, 7), _hpFill);
  }
}
