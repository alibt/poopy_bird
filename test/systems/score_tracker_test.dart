import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/systems/score_tracker.dart';

void main() {
  group('ScoreTracker', () {
    test('accumulates small distance steps without rounding them away', () {
      final score = ScoreTracker(pixelsPerDistancePoint: 10);
      // One second at 60fps and 120px/s: each step alone is worth 0.2 points.
      for (var i = 0; i < 60; i++) {
        score.addDistance(2);
      }
      expect(score.score, 12);
    });

    test('hits add base points times the multiplier', () {
      final score = ScoreTracker();
      expect(score.registerHit(basePoints: 50), 50);
      expect(score.registerHit(basePoints: 50, multiplier: 3), 150);
      score.addBonus(1000);
      expect(score.score, 1200);
    });

    test('splatted cars are counted separately from hits', () {
      final score = ScoreTracker()
        ..registerHit(basePoints: 100)
        ..registerHit(basePoints: 100)
        ..registerCarSplatted();
      expect(score.carsSplatted, 1);
    });

    test('finishRun records a new best only when beaten', () {
      final score = ScoreTracker()..registerHit(basePoints: 50);
      score.finishRun();
      expect(score.best, 50);
      expect(score.isNewBest, isTrue);

      score
        ..reset()
        ..finishRun();
      expect(score.best, 50);
      expect(score.isNewBest, isFalse);
    });

    test('reset clears the run but keeps the best score', () {
      final score = ScoreTracker()
        ..registerHit(basePoints: 50)
        ..registerCarSplatted()
        ..addDistance(500)
        ..finishRun();
      final best = score.best;
      score.reset();
      expect(score.score, 0);
      expect(score.carsSplatted, 0);
      expect(score.best, best);
    });
  });
}
