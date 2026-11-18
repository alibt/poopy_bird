import 'package:flutter/material.dart';

import '../achievements/achievements.dart';
import '../app/progress_controller.dart';
import 'widgets.dart';

/// Shows a banner at the top of the screen for each newly unlocked
/// achievement, one after another, over whatever screen is showing.
class AchievementToastHost extends StatelessWidget {
  const AchievementToastHost({
    super.key,
    required this.controller,
    required this.child,
  });

  final ProgressController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<List<AchievementDefinition>>(
          valueListenable: controller.unlockQueue,
          builder: (context, queue, _) => queue.isEmpty
              ? const SizedBox.shrink()
              : Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _Toast(
                      // A new key per achievement restarts the animation.
                      key: ValueKey(queue.first.id),
                      achievement: queue.first,
                      onDone: controller.dismissUnlock,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Toast extends StatefulWidget {
  const _Toast({super.key, required this.achievement, required this.onDone});

  final AchievementDefinition achievement;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  static const Duration _shown = Duration(milliseconds: 2800);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _shown)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Slide in over the first 12%, out over the last 12%.
        final t = _controller.value;
        final shown = t < 0.12
            ? t / 0.12
            : t > 0.88
                ? (1 - t) / 0.12
                : 1.0;
        final curve = Curves.easeOutBack.transform(shown.clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(0, -80 * (1 - curve)),
          child: Opacity(opacity: shown.clamp(0.0, 1.0), child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onDone,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: brandBrown,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brandYellow, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: brandYellow, size: 30),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Achievement unlocked!',
                        style: TextStyle(color: brandYellow, fontSize: 12)),
                    Text(a.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 14),
                const Icon(Icons.monetization_on_rounded,
                    color: coinGold, size: 20),
                Text(' +${a.coins}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
