import 'package:flutter/foundation.dart';

import '../achievements/achievements.dart';
import '../audio/game_audio.dart';
import '../economy/catalog.dart';
import '../economy/rewards.dart';
import '../juice/feedback.dart';
import '../levels/level_definition.dart';
import '../levels/level_repository.dart';
import '../monetization/ads.dart';
import '../progress/level_result.dart';
import '../progress/player_progress.dart';
import '../progress/progress_repository.dart';
import '../settings/game_settings.dart';
import '../settings/settings_store.dart';

/// App-wide state for menus: worlds, progress, settings, audio and unlocks.
class ProgressController extends ChangeNotifier {
  ProgressController({
    required this.levelRepository,
    required this.progressRepository,
    required this.settingsStore,
    GameAudio? audio,
    this.ads = const NoAds(),
  }) : audio = audio ?? GameAudio() {
    feedback = GameFeedback(audio: this.audio);
  }

  final LevelRepository levelRepository;
  final ProgressRepository progressRepository;
  final SettingsStore settingsStore;
  final RewardedAds ads;
  final GameAudio audio;
  late final GameFeedback feedback;

  List<WorldDefinition> worlds = const [];
  PlayerProgress progress = const PlayerProgress();
  GameSettings settings = const GameSettings();

  /// Debug-only switch that opens every level.
  bool unlockAll = false;

  /// Achievements unlocked but not yet announced, oldest first.
  final ValueNotifier<List<AchievementDefinition>> unlockQueue =
      ValueNotifier(const []);

  void dismissUnlock() {
    final queue = unlockQueue.value;
    if (queue.isNotEmpty) unlockQueue.value = queue.sublist(1);
  }

  UnlockRules get rules => UnlockRules(worlds, progress, unlockAll: unlockAll);

  Future<void> load() async {
    worlds = await levelRepository.loadWorlds();
    progress = await progressRepository.load();
    settings = await settingsStore.load();
    await audio.init();
    feedback.apply(settings);
    notifyListeners();
  }

  Future<void> updateSettings(GameSettings next) async {
    settings = next;
    await settingsStore.save(next);
    feedback.apply(next);
    notifyListeners();
  }

  Future<void> markTutorialSeen() =>
      updateSettings(settings.copyWith(seenTutorial: true));

  /// Stores a finished run and returns the coins it earned.
  Future<RunReward> record(LevelResult result) async {
    final recorded = await progressRepository.record(result);
    progress = recorded.progress;
    if (result.levelId == 'tutorial' && result.outcome.isWin) {
      await markTutorialSeen();
    }
    if (recorded.reward.total > 0) audio.sfx('coin.wav');
    await _checkAchievements(run: result);
    notifyListeners();
    return recorded.reward;
  }

  Future<bool> doubleRunCoins(RunReward reward, LevelResult result) async {
    if (reward.total <= 0) return false;
    if (!await ads.show(AdPlacement.doubleCoins)) return false;
    await _update(progressRepository.grantCoins(
      reward.total,
      reason: '${AdPlacement.doubleCoins.id}:${result.levelId}:'
          '${result.finishedAt.toIso8601String()}',
    ));
    audio.sfx('coin.wav');
    return true;
  }

  Future<void> grantDebugCoins(int amount) {
    assert(kDebugMode);
    return _update(progressRepository.grantCoins(amount, reason: 'debug'));
  }

  Future<void> buyUpgrade(UpgradeId id) =>
      _update(progressRepository.buyUpgrade(id));

  Future<void> buyCosmetic(String id) =>
      _update(progressRepository.buyCosmetic(id));

  Future<void> equip(String id) => _update(progressRepository.equip(id));

  Future<void> _update(Future<PlayerProgress> change) async {
    progress = await change;
    await _checkAchievements();
    notifyListeners();
  }

  Future<void> _checkAchievements({LevelResult? run}) async {
    for (var pass = 0; pass < 3; pass++) {
      final earned = Achievements.newlyEarned(AchievementContext(
        progress: progress,
        worlds: worlds,
        run: pass == 0 ? run : null,
      ));
      if (earned.isEmpty) return;
      progress = await progressRepository
          .unlockAchievements([for (final a in earned) a.id]);
      unlockQueue.value = [...unlockQueue.value, ...earned];
      audio.sfx('achieve.wav');
      feedback.hapticMedium();
    }
  }

  @override
  void dispose() {
    unlockQueue.dispose();
    audio.dispose();
    super.dispose();
  }

  void toggleUnlockAll() {
    unlockAll = !unlockAll;
    notifyListeners();
  }

  (WorldDefinition, int)? locate(String levelId) {
    for (final world in worlds) {
      final index = world.levelIds.indexOf(levelId);
      if (index >= 0) return (world, index);
    }
    return null;
  }

  String? nextLevelId(String levelId) {
    final found = locate(levelId);
    if (found == null) return null;
    final (world, index) = found;
    return index + 1 < world.levelIds.length ? world.levelIds[index + 1] : null;
  }
}
