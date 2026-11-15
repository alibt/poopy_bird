import 'package:flutter/material.dart';

import '../../game/poopy_bird_game.dart';
import '../widgets.dart';

/// The pause button in the top-right corner. Only the button itself takes
/// touches; the rest of the screen still reaches the game.
class PauseButtonOverlay extends StatelessWidget {
  const PauseButtonOverlay({super.key, required this.game});

  final PoopyBirdGame game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 10, 0),
        child: IconButton.filledTonal(
          tooltip: 'Pause',
          onPressed: game.pause,
          icon: const Icon(Icons.pause_rounded),
        ),
      ),
    );
  }
}

class PauseMenuOverlay extends StatelessWidget {
  const PauseMenuOverlay({super.key, required this.game, required this.onQuit});

  final PoopyBirdGame game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Paused',
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w900, color: brandBrown),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: game.resume, child: const Text('Resume')),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                  onPressed: game.restart, child: const Text('Restart')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: onQuit, child: const Text('Quit')),
            ],
          ),
        ],
      ),
    );
  }
}
