import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, Shadow;

import '../game/poopy_bird_game.dart';
import 'run_scoped.dart';
import 'splat_mark.dart';

const Color poopBrown = Color(0xFF6B4423);

/// A burst of brown droplets, e.g. when poop lands.
ParticleSystemComponent splatBurst(
  Vector2 position,
  Random random, {
  int count = 12,
  double power = 1,
}) {
  final paint = Paint()..color = poopBrown;
  return ParticleSystemComponent(
    position: position,
    priority: 40,
    particle: Particle.generate(
      count: count,
      lifespan: 0.6,
      generator: (_) {
        final angle = -pi * (0.1 + random.nextDouble() * 0.8);
        final speed = (80 + random.nextDouble() * 140) * power;
        return AcceleratedParticle(
          acceleration: Vector2(0, 700),
          speed: Vector2(cos(angle), sin(angle)) * speed,
          child: CircleParticle(
            radius: (1.5 + random.nextDouble() * 2.5) * power,
            paint: paint,
          ),
        );
      },
    ),
  );
}

/// Text that floats up and fades out, e.g. "+150 x3".
class FloatingText extends PositionComponent with RunScoped {
  FloatingText(
    this.text, {
    required super.position,
    this.color = const Color(0xFFFFFFFF),
    this.fontSize = 18,
  }) : super(anchor: Anchor.center, priority: 50);

  static const double _lifetime = 0.9;
  static const double _rise = 45;

  final String text;
  final Color color;
  final double fontSize;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= _rise / _lifetime * dt;
    if (_age >= _lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _age / _lifetime).clamp(0.0, 1.0);
    TextPaint(
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            blurRadius: 3,
            color: const Color(0xFF000000).withValues(alpha: alpha),
          ),
        ],
      ),
    ).render(canvas, text, Vector2.zero(), anchor: Anchor.center);
  }
}

/// A poop that missed, left on the road. Scrolls with the road and fades.
class RoadSplat extends SplatMark
    with HasGameReference<PoopyBirdGame>, RunScoped {
  RoadSplat({required super.position, required double radius})
      : super(size: Vector2(radius * 3, radius * 1.2));

  static const double _lifetime = 3;
  double _age = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.x -= game.scrollSpeed * dt;
    opacity = (1 - _age / _lifetime).clamp(0.0, 1.0);
    if (_age >= _lifetime || position.x < -size.x) removeFromParent();
  }
}
