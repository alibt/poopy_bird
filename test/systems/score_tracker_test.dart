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

    test('splats add points and are counted', () {
      final score = ScoreTracker(pointsPerSplat: 50);
      score
        ..registerSplat()
        ..registerSplat();
      expect(score.score, 100);
      expect(score.carsSplatted, 2);
    });

    test('finishRun records a new best only when beaten', () {
      final score = ScoreTracker(pointsPerSplat: 50)..registerSplat();
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
        ..registerSplat()
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
