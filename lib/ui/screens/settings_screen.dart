import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../audio/game_audio.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final s = controller.settings;

    return SkyBackground(
      child: Column(
        children: [
          const ScreenHeader(title: 'Settings'),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Panel(
                  maxWidth: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Toggle(
                        label: 'Music',
                        value: s.music,
                        onChanged: (v) {
                          controller.audio.sfx('ui_tap.wav');
                          controller.updateSettings(s.copyWith(music: v));
                          if (v) {
                            controller.audio.playMusic(GameAudio.menuMusic);
                          }
                        },
                      ),
                      _Toggle(
                        label: 'Sound effects',
                        value: s.sfx,
                        onChanged: (v) {
                          controller.updateSettings(s.copyWith(sfx: v));
                          if (v) controller.audio.sfx('ui_tap.wav');
                        },
                      ),
                      _Toggle(
                        label: 'Haptics',
                        value: s.haptics,
                        onChanged: (v) {
                          controller.audio.sfx('ui_tap.wav');
                          controller.updateSettings(s.copyWith(haptics: v));
                          if (v) controller.feedback.hapticLight();
                        },
                      ),
                      _Toggle(
                        label: 'Left-handed controls',
                        subtitle: 'Poop on the left, flap on the right',
                        value: s.leftHanded,
                        onChanged: (v) {
                          controller.audio.sfx('ui_tap.wav');
                          controller.updateSettings(s.copyWith(leftHanded: v));
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Audio stubs are procedural WAV files in assets/audio/. '
                        'Swap them for Kenney (or other CC0) packs anytime.',
                        style: TextStyle(
                          fontSize: 11,
                          color: brandBrown.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: brandBrown,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: brandBrown),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: brandBrown,
            activeTrackColor: brandYellow,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
