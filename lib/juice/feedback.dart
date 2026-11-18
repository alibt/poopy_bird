import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart';

import '../audio/game_audio.dart';
import '../settings/game_settings.dart';

/// Haptics + camera shake, gated by [GameSettings].
class GameFeedback {
  GameFeedback({required this.audio, GameSettings? settings})
      : settings = settings ?? const GameSettings();

  final GameAudio audio;
  GameSettings settings;

  void apply(GameSettings next) {
    settings = next;
    audio.apply(next);
  }

  void hapticLight() {
    if (!settings.haptics) return;
    HapticFeedback.lightImpact();
  }

  void hapticMedium() {
    if (!settings.haptics) return;
    HapticFeedback.mediumImpact();
  }

  void hapticHeavy() {
    if (!settings.haptics) return;
    HapticFeedback.heavyImpact();
  }

  /// Brief camera shake on the viewfinder (safe to call repeatedly).
  void shake(CameraComponent camera, {double intensity = 6, int pulses = 3}) {
    final viewfinder = camera.viewfinder;
    viewfinder.add(
      SequenceEffect([
        for (var i = 0; i < pulses; i++) ...[
          MoveEffect.by(
            Vector2(intensity * (i.isEven ? 1 : -1), intensity * 0.6),
            EffectController(duration: 0.03),
          ),
          MoveEffect.by(
            Vector2(intensity * (i.isEven ? -1 : 1), -intensity * 0.6),
            EffectController(duration: 0.03),
          ),
        ],
      ]),
    );
  }
}
