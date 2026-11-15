import 'package:flutter/foundation.dart';

import '../levels/level_definition.dart';
import '../levels/level_repository.dart';
import '../progress/level_result.dart';
import '../progress/player_progress.dart';
import '../progress/progress_repository.dart';

/// App-wide state for menus: the world list, the player's progress, and
/// what is unlocked. Screens listen to it through [AppScope].
class ProgressController extends ChangeNotifier {
  ProgressController({
    required this.levelRepository,
    required this.progressRepository,
  });

  final LevelRepository levelRepository;
  final ProgressRepository progressRepository;

  List<WorldDefinition> worlds = const [];
  PlayerProgress progress = const PlayerProgress();

  /// Debug-only switch that opens every level.
  bool unlockAll = false;

  UnlockRules get rules => UnlockRules(worlds, progress, unlockAll: unlockAll);

  Future<void> load() async {
    worlds = await levelRepository.loadWorlds();
    progress = await progressRepository.load();
    notifyListeners();
  }

  Future<void> record(LevelResult result) async {
    progress = await progressRepository.record(result);
    notifyListeners();
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
