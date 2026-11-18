import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import 'car.dart';
import 'effects.dart';

/// World 1 boss. A big, slow truck that takes [CarType.hitPoints] poops.
/// Every few seconds it sprays water that washes nearby cars clean, so they
/// count as escapes again. If it drives off-screen undefeated it loops back
/// around (in Endless, only once more). Placeholder art until M5.
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
  double _wheelAngle = 0;

  static final Paint _cab = Paint()..color = const Color(0xFF1565C0);
  static final Paint _tank = Paint()..color = const Color(0xFF90CAF9);
  static final Paint _stripe = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _window = Paint()..color = const Color(0xFFB3E5FC);
  static final Paint _brush = Paint()..color = const Color(0xFFFFEB3B);
  static final Paint _tire = Paint()..color = const Color(0xFF212121);
  static final Paint _hub = Paint()..color = const Color(0xFF9E9E9E);
  static final Paint _hpBack = Paint()..color = const Color(0x88000000);
  static final Paint _hpFill = Paint()..color = const Color(0xFFFF5252);
  static final Paint _outline = Paint()
    ..color = const Color(0xFF000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final TextPaint _label = TextPaint(
    style: const TextStyle(
      color: Color(0xFF0D47A1),
      fontSize: 16,
      fontWeight: FontWeight.w900,
    ),
  );

  @override
  Future<void> buildVisuals() async {}

  @override
  Vector2 splatPosition(int hit) {
    // Spread the splats along the tank roof.
    final t = (hit - 1) / max(1, type.hitPoints - 1);
    return Vector2(size.x * (0.4 + 0.5 * t), size.y * 0.1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _wheelAngle -= speed * dt / 14;
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
    final w = size.x;
    final h = size.y;
    final wheelY = h - 14;

    // Tank body (rear) and cab (front, facing left).
    final tank = RRect.fromLTRBR(
        w * 0.28, h * 0.08, w, wheelY, const Radius.circular(10));
    final cab =
        RRect.fromLTRBR(0, h * 0.3, w * 0.3, wheelY, const Radius.circular(8));
    canvas.drawRRect(tank, _tank);
    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.42, w * 0.72, 10), _stripe);
    canvas.drawRRect(cab, _cab);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.04, h * 0.38, w * 0.15, h * 0.2), _window);
    canvas.drawRRect(tank, _outline);
    canvas.drawRRect(cab, _outline);
    _label.render(canvas, 'CAR WASH', Vector2(w * 0.64, h * 0.27),
        anchor: Anchor.center);

    // Spinning brushes on the roof.
    for (final x in [w * 0.45, w * 0.82]) {
      canvas.drawCircle(Offset(x, h * 0.08), 10, _brush);
      canvas.drawCircle(Offset(x, h * 0.08), 10, _outline);
    }

    // Wheels.
    for (final x in [w * 0.15, w * 0.55, w * 0.85]) {
      final c = Offset(x, wheelY);
      canvas.drawCircle(c, 14, _tire);
      canvas.drawCircle(c, 6, _hub);
      final spoke = Offset(cos(_wheelAngle), sin(_wheelAngle)) * 10;
      canvas.drawLine(c - spoke, c + spoke, _outline);
    }

    // Health bar.
    final remaining = 1 - hitsTaken / type.hitPoints;
    canvas.drawRect(Rect.fromLTWH(w * 0.2, -14, w * 0.6, 7), _hpBack);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.2, -14, w * 0.6 * remaining, 7), _hpFill);
  }
}
