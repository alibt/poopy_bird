import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/game/config.dart';
import 'package:poopy_bird/levels/level_definition.dart';
import 'package:poopy_bird/levels/level_repository.dart';
import 'package:poopy_bird/systems/car_type.dart';

/// Guards the shipped level files, so content edits can't break the game.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<WorldDefinition> worlds;
  final levels = <String, LevelDefinition>{};
  final laneCount = GameConfig.laneBaselines.length;

  setUpAll(() async {
    final repository = AssetLevelRepository();
    worlds = await repository.loadWorlds();
    for (final world in worlds) {
      for (final id in world.levelIds) {
        levels[id] = await repository.loadLevel(id);
      }
    }
  });

  test('World 1 has 8 levels and a boss; later worlds are coming soon', () {
    expect(worlds.first.levelIds, hasLength(9));
    expect(worlds.skip(1).every((w) => w.comingSoon), isTrue);
  });

  test('level ids are unique across worlds', () {
    final ids = worlds.expand((w) => w.levelIds).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every level is well-formed', () {
    for (final level in levels.values) {
      final where = 'in ${level.id}';
      expect(level.objectives, isNotEmpty, reason: where);
      expect(level.timeLimit, greaterThan(0), reason: where);
      expect(level.stars.two, greaterThan(0), reason: where);
      for (final segment in level.traffic) {
        expect(segment.from, lessThan(segment.to), reason: where);
        expect(segment.to, lessThanOrEqualTo(level.timeLimit), reason: where);
        expect(segment.interval, greaterThan(0), reason: where);
        expect(
            segment.groundSpeedMin, lessThanOrEqualTo(segment.groundSpeedMax),
            reason: where);
        expect(segment.lanes.every((l) => l >= 0 && l < laneCount), isTrue,
            reason: where);
        expect(segment.cars.keys.any((c) => c.isBoss), isFalse,
            reason: 'bosses must be scripted, not random, $where');
      }
      for (final spawn in level.scriptedSpawns) {
        expect(spawn.at, lessThan(level.timeLimit), reason: where);
        expect(spawn.lane, inInclusiveRange(0, laneCount - 1), reason: where);
      }
    }
  });

  test('the last level of each world is its boss, and only that one', () {
    for (final world in worlds.where((w) => !w.comingSoon)) {
      for (final (i, id) in world.levelIds.indexed) {
        final level = levels[id]!;
        final isLast = i == world.levelIds.length - 1;
        expect(level.isBoss, isLast, reason: id);
        if (!isLast) continue;
        expect(level.endWhenObjectivesMet, isTrue, reason: id);
        expect(level.objectives.map((o) => o.type),
            contains(ObjectiveType.defeatBoss),
            reason: id);
        final boss = level.scriptedSpawns.where((s) => s.car.isBoss).toList();
        expect(boss, hasLength(1), reason: id);
        // Random traffic must stay out of the boss's lane.
        expect(level.traffic.every((t) => !t.lanes.contains(boss.single.lane)),
            isTrue,
            reason: id);
      }
    }
  });

  test('objectives that name a car type can actually be met', () {
    for (final level in levels.values) {
      final available = {
        ...level.traffic.expand((t) => t.cars.keys),
        ...level.scriptedSpawns.map((s) => s.car),
      };
      for (final objective
          in level.objectives.where((o) => o.carType != null)) {
        expect(available, contains(objective.carType), reason: level.id);
      }
      if (level.objectives.any((o) => o.type == ObjectiveType.defeatBoss)) {
        expect(available.any((c) => c.isBoss), isTrue, reason: level.id);
      }
    }
  });

  test('levels survive a JSON round trip unchanged', () {
    for (final level in levels.values) {
      final json = level.toJson();
      expect(LevelDefinition.fromJson(json).toJson(), json, reason: level.id);
    }
  });

  test('car types used in levels all exist', () {
    expect(CarType.parse('sportsCar'), CarType.sportsCar);
    expect(() => CarType.parse('hovercar'), throwsFormatException);
  });
}
