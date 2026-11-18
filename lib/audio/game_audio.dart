import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../settings/game_settings.dart';

/// Thin wrapper around FlameAudio that respects [GameSettings] and never
/// crashes the game if a platform can't play sound (tests, missing files).
class GameAudio {
  GameAudio();

  GameSettings settings = const GameSettings();
  bool _ready = false;
  String? _bgm;

  static const List<String> _sfx = [
    'flap.wav',
    'poop.wav',
    'splat.wav',
    'miss.wav',
    'eat.wav',
    'crash.wav',
    'combo.wav',
    'ui_tap.wav',
    'coin.wav',
    'achieve.wav',
  ];

  static const String menuMusic = 'music_menu.wav';
  static const String gameMusic = 'music_game.wav';

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([..._sfx, menuMusic, gameMusic]);
      _ready = true;
    } catch (e, st) {
      _ready = false;
      debugPrint('GameAudio init failed: $e\n$st');
    }
  }

  void apply(GameSettings next) {
    settings = next;
    if (!next.music) {
      stopMusic();
    } else if (_bgm != null) {
      playMusic(_bgm!);
    }
  }

  void sfx(String file, {double volume = 1}) {
    if (!_ready || !settings.sfx) return;
    try {
      FlameAudio.play(file, volume: volume.clamp(0, 1));
    } catch (e) {
      debugPrint('GameAudio sfx $file failed: $e');
    }
  }

  void playMusic(String file, {double volume = 0.45}) {
    _bgm = file;
    if (!_ready || !settings.music) return;
    try {
      FlameAudio.bgm.play(file, volume: volume);
    } catch (e) {
      debugPrint('GameAudio music $file failed: $e');
    }
  }

  void stopMusic() {
    // Never touch FlameAudio.bgm until init succeeded — constructing Bgm
    // creates an AudioPlayer and blows up tests without the plugin.
    if (!_ready) return;
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void dispose() {
    stopMusic();
  }
}
