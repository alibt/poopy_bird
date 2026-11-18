import 'package:flutter/foundation.dart';

import '../achievements/achievements.dart';
import '../economy/catalog.dart';
import '../economy/rewards.dart';
import '../levels/level_definition.dart';
import '../levels/level_repository.dart';
import '../progress/level_result.dart';
import '../progress/player_progress.dart';
import '../monetization/ads.dart';
import '../progress/progress_repository.dart';

/// App-wide state for menus: the world list, the player's progress, and
/// what is unlocked. Screens listen to it through [AppScope].
class ProgressController extends ChangeNotifier {
  ProgressController({
    required this.levelRepository,
    required this.progressRepository,
    this.ads = const NoAds(),
  });

  final LevelRepository levelRepository;
  final ProgressRepository progressRepository;
  final RewardedAds ads;

  List<WorldDefinition> worlds = const [];
  PlayerProgress progress = const PlayerProgress();

  /// Debug-only switch that opens every level.
  bool unlockAll = false;

  /// Achievements unlocked but not yet announced, oldest first. The app's
  /// toast host shows and removes them.
  final ValueNotifier<List<AchievementDefinition>> unlockQueue =
      ValueNotifier(const []);

  /// Removes the first queued achievement once its toast has been shown.
  void dismissUnlock() {
    final queue = unlockQueue.value;
    if (queue.isNotEmpty) unlockQueue.value = queue.sublist(1);
  }

  UnlockRules get rules => UnlockRules(worlds, progress, unlockAll: unlockAll);

  Future<void> load() async {
    worlds = await levelRepository.loadWorlds();
    progress = await progressRepository.load();
    notifyListeners();
  }

  /// Stores a finished run and returns the coins it earned.
  Future<RunReward> record(LevelResult result) async {
    final recorded = await progressRepository.record(result);
    progress = recorded.progress;
    await _checkAchievements(run: result);
    notifyListeners();
    return recorded.reward;
  }

  /// Shows a rewarded ad and, if it was watched, pays [reward] again.
  /// Returns whether the coins were doubled.
  Future<bool> doubleRunCoins(RunReward reward, LevelResult result) async {
    if (reward.total <= 0) return false;
    if (!await ads.show(AdPlacement.doubleCoins)) return false;
    await _update(progressRepository.grantCoins(
      reward.total,
      reason: '${AdPlacement.doubleCoins.id}:${result.levelId}:'
          '${result.finishedAt.toIso8601String()}',
    ));
    return true;
  }

  /// Debug builds only: free coins for testing the shop.
  Future<void> grantDebugCoins(int amount) {
    assert(kDebugMode);
    return _update(progressRepository.grantCoins(amount, reason: 'debug'));
  }

  /// Throws [ShopException] if the purchase isn't possible.
  Future<void> buyUpgrade(UpgradeId id) =>
      _update(progressRepository.buyUpgrade(id));

  /// Throws [ShopException] if the purchase isn't possible.
  Future<void> buyCosmetic(String id) =>
      _update(progressRepository.buyCosmetic(id));

  Future<void> equip(String id) => _update(progressRepository.equip(id));

  Future<void> _update(Future<PlayerProgress> change) async {
    progress = await change;
    await _checkAchievements();
    notifyListeners();
  }

  /// Unlocks whatever the latest change earned. Repeats because an
  /// achievement's coins can earn another (e.g. "Earn 5,000 coins").
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
    }
  }

  @override
  void dispose() {
    unlockQueue.dispose();
    super.dispose();
  }

  void toggleUnlockAll() {
    unlockAll = !unlockAll;
    notifyListeners();
  }

  /// The world containing [levelId] and the level's index in it.
  (WorldDefinition, int)? locate(String levelId) {
    for (final world in worlds) {
      final index = world.levelIds.indexOf(levelId);
      if (index >= 0) return (world, index);
    }
    return null;
  }

  /// The level after [levelId] in the same world, or null if it was last.
  String? nextLevelId(String levelId) {
    final found = locate(levelId);
    if (found == null) return null;
    final (world, index) = found;
    return index + 1 < world.levelIds.length ? world.levelIds[index + 1] : null;
  }
}
