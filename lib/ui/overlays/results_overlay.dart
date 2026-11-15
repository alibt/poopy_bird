import 'package:flutter/material.dart';

import '../../game/poopy_bird_game.dart';
import '../../progress/level_result.dart';
import '../widgets.dart';

/// End-of-run summary: outcome, stars, score, objectives, what next.
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay({
    super.key,
    required this.game,
    required this.onQuit,
    this.onNext,
  });

  final PoopyBirdGame game;
  final VoidCallback onQuit;

  /// Null when there is no next level to go to.
  final VoidCallback? onNext;

  String get _title {
    final level = game.plan.level;
    return switch (game.outcome!) {
      RunOutcome.won =>
        level?.isBoss ?? false ? 'Boss defeated!' : 'Level complete!',
      RunOutcome.crashed => 'Crash!',
      RunOutcome.rageOut => 'The cars are angry!',
      RunOutcome.timeUp => "Time's up!",
      RunOutcome.objectiveFailed => 'Too many cars got away!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final result = game.lastResult!;
    final level = game.plan.level;
    final won = result.outcome.isWin;
    final tracker = game.objectives;

    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: won ? brandBrown : Colors.red.shade700,
            ),
          ),
          if (level != null) ...[
            const SizedBox(height: 6),
            StarRow(stars: result.stars, size: 40),
          ],
          const SizedBox(height: 8),
          Text(
            'Score: ${result.score}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            game.score.isNewBest ? 'New best!' : 'Best: ${game.score.best}',
            style: TextStyle(
              color:
                  game.score.isNewBest ? Colors.green.shade700 : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
              'Cars splatted: ${result.carsSplatted}   Best combo: x${result.bestCombo}'),
          if (tracker.objectives.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < tracker.objectives.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tracker.isMet(i)
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 18,
                    color: tracker.isMet(i)
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                      '${tracker.objectives[i].description}  ${tracker.progressLabel(i)}'),
                ],
              ),
          ],
          if (level != null && won && result.stars < 3)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                result.stars < 2
                    ? '${level.stars.two} points for 2 stars'
                    : '${level.stars.three} points for 3 stars',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(onPressed: onQuit, child: const Text('Menu')),
              const SizedBox(width: 10),
              OutlinedButton(
                  onPressed: game.restart, child: const Text('Retry')),
              if (onNext != null) ...[
                const SizedBox(width: 10),
                FilledButton(onPressed: onNext, child: const Text('Next')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
