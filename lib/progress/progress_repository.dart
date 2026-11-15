import 'level_result.dart';
import 'player_progress.dart';

/// Where player progress lives. M2 keeps it in memory; M3 adds on-device
/// storage, and a backend-synced implementation can replace either later.
abstract interface class ProgressRepository {
  Future<PlayerProgress> load();

  /// Stores [result] and returns the updated progress.
  Future<PlayerProgress> record(LevelResult result);
}

class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([this._progress = const PlayerProgress()]);

  PlayerProgress _progress;
  final List<LevelResult> history = [];

  @override
  Future<PlayerProgress> load() async => _progress;

  @override
  Future<PlayerProgress> record(LevelResult result) async {
    history.add(result);
    return _progress = _progress.withResult(result);
  }
}
