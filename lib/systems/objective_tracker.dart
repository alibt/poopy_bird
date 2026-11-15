import 'dart:math';

import '../levels/level_definition.dart';
import 'car_type.dart';

/// Tracks progress toward a level's objectives as game events arrive.
class ObjectiveTracker {
  ObjectiveTracker(this.objectives)
      : _progress = List.filled(objectives.length, 0);

  final List<ObjectiveDefinition> objectives;
  final List<int> _progress;

  int escapes = 0;

  int progressOf(int i) => _progress[i];

  bool isMet(int i) {
    final o = objectives[i];
    return o.type == ObjectiveType.maxEscapes
        ? escapes <= o.count
        : _progress[i] >= o.count;
  }

  /// Only "max escapes" objectives can fail before the level ends.
  bool isFailed(int i) =>
      objectives[i].type == ObjectiveType.maxEscapes && !isMet(i);

  bool get allMet => Iterable<int>.generate(objectives.length).every(isMet);
  bool get anyFailed => Iterable<int>.generate(objectives.length).any(isFailed);

  /// Short progress text for the HUD, e.g. "3/8".
  String progressLabel(int i) {
    final o = objectives[i];
    return switch (o.type) {
      ObjectiveType.maxEscapes => '$escapes/${o.count}',
      ObjectiveType.defeatBoss => isMet(i) ? 'done' : '',
      _ => '${min(_progress[i], o.count)}/${o.count}',
    };
  }

  void onSplat(CarType type) => _bump(
        (o) =>
            o.type == ObjectiveType.splatCars &&
            (o.carType == null || o.carType == type),
        (current) => current + 1,
      );

  void onCombo(int combo) => _bump(
        (o) => o.type == ObjectiveType.reachCombo,
        (current) => max(current, combo),
      );

  void onScore(int score) => _bump(
        (o) => o.type == ObjectiveType.reachScore,
        (current) => max(current, score),
      );

  void onBossDefeated() => _bump(
        (o) => o.type == ObjectiveType.defeatBoss,
        (current) => current + 1,
      );

  void onEscape() => escapes++;

  void _bump(
    bool Function(ObjectiveDefinition) applies,
    int Function(int current) next,
  ) {
    for (var i = 0; i < objectives.length; i++) {
      if (applies(objectives[i])) _progress[i] = next(_progress[i]);
    }
  }
}
