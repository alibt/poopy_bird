/// Player preferences (audio, haptics, controls). Separate from progress.
class GameSettings {
  const GameSettings({
    this.music = true,
    this.sfx = true,
    this.haptics = true,
    this.leftHanded = false,
    this.seenTutorial = false,
  });

  final bool music;
  final bool sfx;
  final bool haptics;

  /// Swap flap/poop screen halves for left-handed play.
  final bool leftHanded;

  /// True after the tutorial level has been finished once.
  final bool seenTutorial;

  GameSettings copyWith({
    bool? music,
    bool? sfx,
    bool? haptics,
    bool? leftHanded,
    bool? seenTutorial,
  }) =>
      GameSettings(
        music: music ?? this.music,
        sfx: sfx ?? this.sfx,
        haptics: haptics ?? this.haptics,
        leftHanded: leftHanded ?? this.leftHanded,
        seenTutorial: seenTutorial ?? this.seenTutorial,
      );

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        music: json['music'] as bool? ?? true,
        sfx: json['sfx'] as bool? ?? true,
        haptics: json['haptics'] as bool? ?? true,
        leftHanded: json['leftHanded'] as bool? ?? false,
        seenTutorial: json['seenTutorial'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'music': music,
        'sfx': sfx,
        'haptics': haptics,
        'leftHanded': leftHanded,
        'seenTutorial': seenTutorial,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSettings &&
          music == other.music &&
          sfx == other.sfx &&
          haptics == other.haptics &&
          leftHanded == other.leftHanded &&
          seenTutorial == other.seenTutorial;

  @override
  int get hashCode =>
      Object.hash(music, sfx, haptics, leftHanded, seenTutorial);
}
