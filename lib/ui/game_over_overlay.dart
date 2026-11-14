import 'package:flutter/material.dart';

import '../game/poopy_bird_game.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});

  static const String id = 'GameOver';

  final PoopyBirdGame game;

  @override
  Widget build(BuildContext context) {
    final rage = game.gameOverReason == GameOverReason.rage;
    final score = game.score;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rage ? 'THE CARS ARE ANGRY!' : 'CRASH!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: rage ? Colors.redAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Score: ${score.score}',
              style: const TextStyle(fontSize: 24, color: Colors.yellowAccent),
            ),
            Text(
              'Cars splatted: ${score.carsSplatted}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              score.isNewBest ? 'New best!' : 'Best: ${score.best}',
              style: TextStyle(
                fontSize: 18,
                color:
                    score.isNewBest ? Colors.lightGreenAccent : Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: game.restart,
              child: const Text('Play again'),
            ),
          ],
        ),
      ),
    );
  }
}
