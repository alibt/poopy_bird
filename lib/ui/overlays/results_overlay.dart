import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../economy/rewards.dart';

import '../../game/poopy_bird_game.dart';
import '../../progress/level_result.dart';
import '../widgets.dart';

/// End-of-run summary: outcome, stars, score, objectives, what next.
class ResultsOverlay extends StatelessWidget {
  const ResultsOverlay({
    super.key,
    required this.game,
    required this.reward,
    required this.onQuit,
    this.onNext,
    this.onDoubleCoins,
  });

  final PoopyBirdGame game;

  /// Coins for this run, null while they are being stored.
  final ValueListenable<RunReward?> reward;
  final VoidCallback onQuit;

  /// Null when there is no next level to go to.
  final VoidCallback? onNext;

  /// Shows a rewarded ad to double the coins; null when no ad is available.
  final Future<bool> Function(RunReward reward)? onDoubleCoins;

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
          const SizedBox(height: 8),
          ValueListenableBuilder<RunReward?>(
            valueListenable: reward,
            builder: (context, value, _) => value == null
                ? const SizedBox(height: 28)
                : _CoinsEarned(reward: value, onDouble: onDoubleCoins),
          ),
          const SizedBox(height: 10),
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

/// "+42 coins", with a button to double them by watching an ad.
class _CoinsEarned extends StatefulWidget {
  const _CoinsEarned({required this.reward, this.onDouble});

  final RunReward reward;
  final Future<bool> Function(RunReward reward)? onDouble;

  @override
  State<_CoinsEarned> createState() => _CoinsEarnedState();
}

class _CoinsEarnedState extends State<_CoinsEarned> {
  bool _busy = false;
  bool _doubled = false;

  Future<void> _double() async {
    setState(() => _busy = true);
    final doubled = await widget.onDouble!(widget.reward);
    if (mounted) {
      setState(() {
        _busy = false;
        _doubled = doubled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final total = reward.total * (_doubled ? 2 : 1);
    final bonuses = [
      if (reward.newStarCoins > 0) '${reward.newStarCoins} new stars',
      if (reward.firstClearBonus > 0) '${reward.firstClearBonus} first clear',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade900)),
            CoinCount(coins: total, size: 28),
            if (_doubled)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text('x2!',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade700)),
              ),
            if (widget.onDouble != null && reward.total > 0 && !_doubled) ...[
              const SizedBox(width: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                onPressed: _busy ? null : _double,
                icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                label: Text(_busy ? '...' : 'Double it'),
              ),
            ],
          ],
        ),
        if (bonuses.isNotEmpty)
          Text('incl. ${bonuses.join(', ')}',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
