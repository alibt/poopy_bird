import 'package:flutter/material.dart';

import '../../achievements/trophies.dart';
import '../../app/app_scope.dart';
import '../../progress/lifetime_stats.dart';
import '../widgets.dart';

/// Cups derived from progress, plus the personal Endless top list.
class TrophyRoomScreen extends StatelessWidget {
  const TrophyRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final trophies = Trophies.all(controller.progress, controller.worlds);
    final top = controller.progress.endlessTop;

    return DefaultTabController(
      length: 2,
      child: SkyBackground(
        child: Column(
          children: [
            const ScreenHeader(title: 'Trophy Room'),
            const TabBar(
              labelColor: brandBrown,
              indicatorColor: brandBrown,
              labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              tabs: [
                Tab(text: 'Cups', height: 36),
                Tab(text: 'Endless', height: 36),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _CupsTab(trophies: trophies),
                  _EndlessTab(top: top, best: controller.progress.endlessBest),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupsTab extends StatelessWidget {
  const _CupsTab({required this.trophies});

  final List<Trophy> trophies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 150,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: trophies.length,
      itemBuilder: (context, i) => _TrophyCard(trophy: trophies[i]),
    );
  }
}

class _TrophyCard extends StatelessWidget {
  const _TrophyCard({required this.trophy});

  final Trophy trophy;

  Color get _metal => switch (trophy.tier) {
        TrophyTier.none => brandBrown.withValues(alpha: 0.35),
        TrophyTier.bronze => const Color(0xFFCD7F32),
        TrophyTier.silver => const Color(0xFF9E9E9E),
        TrophyTier.gold => const Color(0xFFFFB300),
      };

  @override
  Widget build(BuildContext context) {
    final next = trophy.nextGoal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandBrown, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                switch (trophy.tier) {
                  TrophyTier.gold => 'assets/images/trophy_gold.png',
                  TrophyTier.silver => 'assets/images/trophy_silver.png',
                  TrophyTier.bronze => 'assets/images/trophy_bronze.png',
                  TrophyTier.none => 'assets/images/medal.png',
                },
                width: 36,
                height: 36,
                color: trophy.tier == TrophyTier.none ? _metal : null,
                colorBlendMode:
                    trophy.tier == TrophyTier.none ? BlendMode.srcIn : null,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.emoji_events_rounded, color: _metal, size: 32),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trophy.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: brandBrown,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            trophy.tier == TrophyTier.none
                ? 'Locked'
                : trophy.tier.name[0].toUpperCase() +
                    trophy.tier.name.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _metal,
            ),
          ),
          const Spacer(),
          Text(
            next ?? 'Complete!',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: brandBrown.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndlessTab extends StatelessWidget {
  const _EndlessTab({required this.top, required this.best});

  final List<EndlessRun> top;
  final int best;

  @override
  Widget build(BuildContext context) {
    if (top.isEmpty) {
      return Center(
        child: Panel(
          child: Text(
            best > 0
                ? 'Best score: $best\nPlay Endless again to fill the board.'
                : 'Clear World 1, then play Endless to fill this board.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: brandBrown, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: top.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final run = top[i];
        final place = i + 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: brandBrown, width: 2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#$place',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: brandBrown,
                    fontSize: 18,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${run.score} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: brandBrown,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${run.distance} m · ${run.durationSeconds.round()}s',
                      style: TextStyle(
                        color: brandBrown.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${run.finishedAt.toLocal().year}-'
                '${run.finishedAt.toLocal().month.toString().padLeft(2, '0')}-'
                '${run.finishedAt.toLocal().day.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: brandBrown.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
