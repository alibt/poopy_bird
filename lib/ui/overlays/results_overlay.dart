import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../economy/rewards.dart';
import '../../game/poopy_bird_game.dart';
import '../../progress/level_result.dart';
import '../widgets.dart';

/// End-of-run summary: compact, fully centered, fits a phone without scrolling.
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
      RunOutcome.objectiveFailed => 'Too many got away!',
    };
  }

  @override
  Widget build(BuildContext context) {
    final result = game.lastResult!;
    final level = game.plan.level;
    final won = result.outcome.isWin;
    final tracker = game.objectives;

    return OverlayPanel(
      scrollable: false,
      maxWidth: 360,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: won ? brandBrown : Colors.red.shade700,
            ),
          ),
          if (level != null) ...[
            const SizedBox(height: 2),
            Center(child: StarRow(stars: result.stars, size: 26)),
          ],
          const SizedBox(height: 6),
          Text(
            '${result.score}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            game.score.isNewBest ? 'New best!' : 'Best ${game.score.best}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: game.score.isNewBest
                  ? Colors.green.shade700
                  : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (result.isEndless) _EndlessRank(runId: result.runId),
          Text(
            '${result.carsSplatted} splat · x${result.bestCombo} combo',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (tracker.objectives.isNotEmpty) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Mission',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.brown.shade700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < tracker.objectives.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  tracker.isMet(i)
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 15,
                                  color: tracker.isMet(i)
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '  ${tracker.objectives[i].description}  ${tracker.progressLabel(i)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (level != null && won && result.stars < 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                result.stars < 2
                    ? '${level.stars.two} for ★★'
                    : '${level.stars.three} for ★★★',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 6),
          ValueListenableBuilder<RunReward?>(
            valueListenable: reward,
            builder: (context, value, _) => value == null
                ? const SizedBox(height: 22)
                : _CoinsEarned(reward: value, onDouble: onDoubleCoins),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onQuit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Menu'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: game.restart,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Retry'),
                ),
              ),
              if (onNext != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Personal Endless board place, once the run has been stored.
class _EndlessRank extends StatelessWidget {
  const _EndlessRank({required this.runId});

  final String runId;

  @override
  Widget build(BuildContext context) {
    final rank = AppScope.of(context).progress.endlessRankOf(runId);
    if (rank == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'Board #$rank',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.green.shade700,
          fontSize: 13,
        ),
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
    final showDouble = _doubled || reward.autoDoubled;
    final total = reward.total * (showDouble ? 2 : 1);
    final bonuses = [
      if (reward.newStarCoins > 0) '${reward.newStarCoins} stars',
      if (reward.firstClearBonus > 0) '${reward.firstClearBonus} clear',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber.shade900)),
            const SizedBox(width: 2),
            CoinCount(coins: total, size: 24),
            if (showDouble) ...[
              const SizedBox(width: 6),
              Text(reward.autoDoubled ? 'x2' : 'x2!',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.green.shade700)),
            ],
          ],
        ),
        if (bonuses.isNotEmpty)
          Text('incl. ${bonuses.join(', ')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54)),
        if (widget.onDouble != null && reward.total > 0 && !showDouble)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: _busy ? null : _double,
              icon: const Icon(Icons.ondemand_video_rounded, size: 16),
              label: Text(_busy ? '...' : 'Double',
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
      ],
    );
  }
}
