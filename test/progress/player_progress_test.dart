import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/levels/level_definition.dart';
import 'package:poopy_bird/progress/level_result.dart';
import 'package:poopy_bird/progress/player_progress.dart';
import 'package:poopy_bird/progress/progress_repository.dart';

LevelResult _result(String id, {int stars = 1, int score = 1000}) =>
    LevelResult(
      levelId: id,
      levelVersion: 1,
      outcome: stars > 0 ? RunOutcome.won : RunOutcome.crashed,
      stars: stars,
      score: score,
      carsSplatted: 5,
      bestCombo: 2,
      escapes: 1,
      durationSeconds: 40,
      finishedAt: DateTime.utc(2026, 11, 15, 12),
    );

const _worlds = [
  WorldDefinition(id: 'w1', name: 'One', levelIds: ['a', 'b']),
  WorldDefinition(id: 'w2', name: 'Two', levelIds: ['c']),
  WorldDefinition(id: 'w3', name: 'Three', levelIds: [], comingSoon: true),
];

void main() {
  group('PlayerProgress', () {
    test('keeps the best stars and score per level and counts plays', () {
      final progress = const PlayerProgress()
          .withResult(_result('a', stars: 2, score: 900))
          .withResult(_result('a', stars: 1, score: 1500))
          .withResult(_result('a', stars: 0, score: 50));
      final record = progress.recordFor('a');
      expect(record.bestStars, 2);
      expect(record.bestScore, 1500);
      expect(record.plays, 3);
      expect(progress.totalStars, 2);
    });

    test('endless results only update the endless best', () {
      final progress = const PlayerProgress()
          .withResult(_result(LevelResult.endlessId, stars: 0, score: 3000))
          .withResult(_result(LevelResult.endlessId, stars: 0, score: 100));
      expect(progress.endlessBest, 3000);
      expect(progress.levels, isEmpty);
    });

    test('JSON round trip, and newer schemas are rejected', () {
      final progress = const PlayerProgress()
          .withResult(_result('a', stars: 3))
          .withResult(_result(LevelResult.endlessId, score: 42));
      final json = progress.toJson();
      expect(PlayerProgress.fromJson(json).toJson(), json);
      expect(
        () => PlayerProgress.fromJson({...json, 'schemaVersion': 99}),
        throwsFormatException,
      );
    });

    test('LevelResult JSON round trip', () {
      final json = _result('a').toJson();
      expect(LevelResult.fromJson(json).toJson(), json);
    });
  });

  group('UnlockRules', () {
    test('levels open in order; worlds open when the previous is complete', () {
      var rules = const UnlockRules(_worlds, PlayerProgress());
      expect(rules.isLevelUnlocked(_worlds[0], 0), isTrue);
      expect(rules.isLevelUnlocked(_worlds[0], 1), isFalse);
      expect(rules.isWorldUnlocked(_worlds[1]), isFalse);
      expect(rules.isEndlessUnlocked, isFalse);

      var progress = const PlayerProgress().withResult(_result('a'));
      rules = UnlockRules(_worlds, progress);
      expect(rules.isLevelUnlocked(_worlds[0], 1), isTrue);
      expect(rules.isWorldUnlocked(_worlds[1]), isFalse);

      progress = progress.withResult(_result('b'));
      rules = UnlockRules(_worlds, progress);
      expect(rules.isWorldUnlocked(_worlds[1]), isTrue);
      expect(rules.isEndlessUnlocked, isTrue);
    });

    test('a failed run does not unlock the next level', () {
      final rules = UnlockRules(
        _worlds,
        const PlayerProgress().withResult(_result('a', stars: 0)),
      );
      expect(rules.isLevelUnlocked(_worlds[0], 1), isFalse);
    });

    test('unlockAll opens everything except coming-soon worlds', () {
      const rules = UnlockRules(_worlds, PlayerProgress(), unlockAll: true);
      expect(rules.isLevelUnlocked(_worlds[1], 0), isTrue);
      expect(rules.isEndlessUnlocked, isTrue);
      expect(rules.isWorldUnlocked(_worlds[2]), isFalse);
    });
  });

  test('InMemoryProgressRepository records results', () async {
    final repository = InMemoryProgressRepository();
    final updated = await repository.record(_result('a', stars: 2));
    expect(updated.recordFor('a').bestStars, 2);
    expect((await repository.load()).recordFor('a').bestStars, 2);
    expect(repository.history, hasLength(1));
  });
}
