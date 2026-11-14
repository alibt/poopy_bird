import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/poopy_bird_game.dart';

/// Score, best score and rage bar. Lives on the camera viewport, so it uses
/// screen coordinates and ignores camera movement.
class Hud extends PositionComponent with HasGameReference<PoopyBirdGame> {
  static const double _barHeight = 10;

  late final RectangleComponent _rageBackground;
  late final RectangleComponent _rageFill;
  late final TextComponent _score;
  late final TextComponent _best;

  int _shownScore = -1;
  int _shownBest = -1;

  @override
  Future<void> onLoad() async {
    _rageBackground = RectangleComponent(
      size: Vector2(0, _barHeight),
      paint: Paint()..color = const Color(0x44220000),
    );
    _rageFill = RectangleComponent(
      size: Vector2(0, _barHeight),
      paint: Paint()..color = const Color(0xFFFF2200),
    );
    final rageLabel = TextComponent(
      text: 'RAGE',
      position: Vector2(8, 1),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF6644),
          fontSize: 8,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
    );
    _score = TextComponent(
      position: Vector2(16, 14),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
    );
    _best = TextComponent(
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
    );
    addAll([_rageBackground, _rageFill, rageLabel, _score, _best]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final width = game.size.x;
    _rageBackground.size.x = width;
    _rageFill.size.x = width * game.rage.value;
    _best.position.setValues(width - 16, 14);

    final score = game.score.score;
    if (score != _shownScore) {
      _shownScore = score;
      _score.text = 'Score: $score';
    }
    final best = game.score.best;
    if (best != _shownBest) {
      _shownBest = best;
      _best.text = 'Best: $best';
    }
  }
}
