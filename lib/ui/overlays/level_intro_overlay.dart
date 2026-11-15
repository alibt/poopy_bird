import 'package:flutter/material.dart';

import '../../game/poopy_bird_game.dart';
import '../widgets.dart';

/// Shown before a level starts: name, description and objectives.
class LevelIntroOverlay extends StatelessWidget {
  const LevelIntroOverlay(
      {super.key, required this.game, required this.onBack});

  final PoopyBirdGame game;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final level = game.plan.level!;
    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.isBoss ? 'BOSS: ${level.name}' : level.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: brandBrown),
          ),
          if (level.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(level.description, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          for (final objective in level.objectives)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded, size: 18, color: brandBrown),
                  const SizedBox(width: 6),
                  Text(
                    objective.description,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${level.timeLimit.round()} seconds',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 12),
              FilledButton(onPressed: game.startRun, child: const Text('GO!')),
            ],
          ),
        ],
      ),
    );
  }
}
