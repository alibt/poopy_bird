import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Colors, FontWeight, Shadow, TextStyle;

import '../game/poopy_bird_game.dart';
import 'effects.dart';

/// Score, best score, rage bar, ammo, combo and power-up status. Lives on
/// the camera viewport, so it uses screen coordinates.
class Hud extends PositionComponent with HasGameReference<PoopyBirdGame> {
  Hud() : super(priority: 100);

  static const double _barHeight = 10;
  static const double _pipRadius = 6;
  static const double _pipSpacing = 16;

  /// How long the ammo row flashes red after trying to poop on empty.
  static const double _emptyFlashTime = 0.4;

  late final TextComponent _score;
  late final TextComponent _best;
  late final TextComponent _combo;
  late final TextComponent _powerUp;

  int _shownScore = -1;
  int _shownBest = -1;
  int _shownCombo = -1;
  String _shownPowerUp = '';
  double _emptyFlash = 0;

  final Paint _rageBackground = Paint()..color = const Color(0x44220000);
  final Paint _rageFill = Paint()..color = const Color(0xFFFF2200);
  final Paint _pipFull = Paint()..color = poopBrown;
  final Paint _pipDigesting = Paint()..color = const Color(0x886B4423);
  final Paint _pipBig = Paint()..color = const Color(0xFFE6C27A);
  final Paint _pipOutline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _comboBar = Paint()..color = const Color(0xFFFFD600);

  static TextPaint _text(double size, Color color, {bool bold = true}) =>
      TextPaint(
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      );

  @override
  Future<void> onLoad() async {
    final rageLabel = TextComponent(
      text: 'RAGE',
      position: Vector2(8, 1),
      textRenderer: _text(8, const Color(0xFFFF6644)),
    );
    _score = TextComponent(
      position: Vector2(16, 14),
      textRenderer: _text(20, Colors.white),
    );
    _best = TextComponent(
      anchor: Anchor.topRight,
      textRenderer: _text(16, Colors.white70, bold: false),
    );
    _combo = TextComponent(
      anchor: Anchor.topCenter,
      textRenderer: _text(26, const Color(0xFFFFD600)),
    );
    _powerUp = TextComponent(
      position: Vector2(16, 66),
      textRenderer: _text(14, const Color(0xFFFFAB40)),
    );
    addAll([rageLabel, _score, _best, _combo, _powerUp]);
  }

  /// Flash the ammo row to show the belly is empty.
  void flashEmpty() => _emptyFlash = _emptyFlashTime;

  @override
  void update(double dt) {
    super.update(dt);
    _emptyFlash = (_emptyFlash - dt).clamp(0, _emptyFlashTime);
    _best.position.setValues(game.size.x - 16, 14);
    _combo.position.setValues(game.size.x / 2, 14);

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
    final combo = game.combo.count;
    if (combo != _shownCombo) {
      _shownCombo = combo;
      _combo.text = combo >= 2 ? 'COMBO x${game.combo.multiplier}' : '';
    }
    final belly = game.belly;
    final powerUp = [
      if (belly.isRapidFire) 'CHILI ${belly.rapidFireLeft.ceil()}s',
      if (belly.bigPoopsLeft > 0) 'BIG x${belly.bigPoopsLeft}',
    ].join('   ');
    if (powerUp != _shownPowerUp) {
      _shownPowerUp = powerUp;
      _powerUp.text = powerUp;
    }
  }

  @override
  void render(Canvas canvas) {
    final width = game.size.x;

    // Rage bar
    canvas.drawRect(Rect.fromLTWH(0, 0, width, _barHeight), _rageBackground);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width * game.rage.value, _barHeight),
      _rageFill,
    );

    // Ammo pips: filled = ready, faded = being digested, gold = big poops.
    final belly = game.belly;
    _pipOutline.color =
        _emptyFlash > 0 ? const Color(0xFFFF1744) : const Color(0xCC000000);
    for (var i = 0; i < belly.capacity; i++) {
      final center = Offset(16 + _pipRadius + i * _pipSpacing, 50);
      if (i < belly.ammo) {
        canvas.drawCircle(center, _pipRadius, _pipFull);
      } else if (i == belly.ammo) {
        canvas.drawCircle(
          center,
          _pipRadius * belly.digestionProgress,
          _pipDigesting,
        );
      }
      canvas.drawCircle(center, _pipRadius, _pipOutline);
    }
    for (var i = 0; i < belly.bigPoopsLeft; i++) {
      final center = Offset(
        16 + _pipRadius + (belly.capacity + i) * _pipSpacing + 6,
        50,
      );
      canvas.drawCircle(center, _pipRadius + 1, _pipBig);
      canvas.drawCircle(center, _pipRadius + 1, _pipOutline);
    }

    // Combo timer bar under the combo text.
    if (game.combo.count >= 2) {
      const barWidth = 120.0;
      final left = width / 2 - barWidth / 2;
      canvas.drawRect(
        Rect.fromLTWH(left, 46, barWidth * game.combo.timeLeftFraction, 4),
        _comboBar,
      );
    }
  }
}
