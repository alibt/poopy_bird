import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopy_bird/app/app.dart';
import 'package:poopy_bird/app/progress_controller.dart';
import 'package:poopy_bird/levels/level_repository.dart';
import 'package:poopy_bird/economy/catalog.dart';
import 'package:poopy_bird/game/poopy_bird_game.dart';
import 'package:poopy_bird/progress/level_result.dart';
import 'package:poopy_bird/progress/player_progress.dart';
import 'package:poopy_bird/progress/progress_repository.dart';

ProgressController _controller([PlayerProgress? progress]) =>
    ProgressController(
      levelRepository: AssetLevelRepository(),
      progressRepository: InMemoryProgressRepository(progress),
    );

LevelResult _win(String id) => LevelResult(
      levelId: id,
      levelVersion: 1,
      outcome: RunOutcome.won,
      stars: 2,
      score: 1500,
      carsSplatted: 6,
      bestCombo: 3,
      escapes: 0,
      durationSeconds: 40,
      finishedAt: DateTime.utc(2026, 11, 15),
    );

/// Landscape phone size, like the real game.
Future<void> _useLandscape(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2400, 1080);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Lets real async work (asset and level loading) run, pumping frames,
/// until no loading spinner is showing. Doesn't wait for animations to end,
/// because a running game never stops animating.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 16));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  // rootBundle caches asset futures, and a future cached in one test's fake
  // async zone never completes in the next test. Start each test fresh.
  setUp(rootBundle.clear);

  testWidgets('menus: play through to World 1 with only level 1 open',
      (tester) async {
    await _useLandscape(tester);
    await tester.pumpWidget(PoopyBirdApp(controller: _controller()));
    await _settle(tester);

    expect(find.text('POOPY BIRD'), findsOneWidget);
    expect(find.text('Complete Suburbs to unlock'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('World Map'), findsOneWidget);
    expect(find.text('Suburbs'), findsOneWidget);
    expect(find.text('Coming soon'), findsWidgets);

    await tester.tap(find.text('Suburbs'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    // Levels 2-8 and the boss are locked.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(8));
  });

  testWidgets('winning a level unlocks the next one and shows its stars',
      (tester) async {
    await _useLandscape(tester);
    final controller = _controller();
    await tester.pumpWidget(PoopyBirdApp(controller: controller));
    await _settle(tester);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suburbs'));
    await tester.pumpAndSettle();

    await tester.runAsync(() => controller.record(_win('w1_l1')));
    await _settle(tester);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(7));
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });

  testWidgets('completing World 1 unlocks Endless', (tester) async {
    await _useLandscape(tester);
    final controller = _controller();
    await tester.pumpWidget(PoopyBirdApp(controller: controller));
    await _settle(tester);

    for (final id in controller.worlds.first.levelIds) {
      await tester.runAsync(() => controller.record(_win(id)));
    }
    await _settle(tester);
    expect(find.text('Complete Suburbs to unlock'), findsNothing);
    final endless = tester.widget<ButtonStyleButton>(
      find.ancestor(
          of: find.text('Endless'),
          matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(endless.enabled, isTrue);
  });

  testWidgets('opening a level shows its intro with objectives',
      (tester) async {
    await _useLandscape(tester);
    await tester.pumpWidget(PoopyBirdApp(controller: _controller()));
    await _settle(tester);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suburbs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 400));
    // Let the level JSON and sprites load, then let the game mount.
    for (var i = 0; i < 10 && find.text('GO!').evaluate().isEmpty; i++) {
      await _settle(tester);
    }

    expect(find.text('First Flight'), findsOneWidget);
    expect(find.text('Splat 5 cars'), findsOneWidget);
    expect(find.text('GO!'), findsOneWidget);
  });

  testWidgets('the shop sells upgrades and cosmetics for coins',
      (tester) async {
    await _useLandscape(tester);
    final controller = _controller(const PlayerProgress(coins: 400));
    await tester.pumpWidget(PoopyBirdApp(controller: controller));
    await _settle(tester);
    expect(find.text('400'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();
    expect(find.text('Bigger Belly'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy_belly')));
    await _settle(tester);
    expect(controller.progress.upgradeTier(UpgradeId.belly), 1);
    expect(controller.progress.coins, 250);
    expect(find.text('7 poops → 8 poops'), findsOneWidget);

    // Too expensive now: refused with a message, nothing spent.
    await tester.tap(find.byKey(const ValueKey('buy_belly')));
    await _settle(tester);
    expect(find.text('Not enough coins yet!'), findsOneWidget);
    expect(controller.progress.coins, 250);

    // Let the message time out so it doesn't cover the cards.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Looks'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy_poop_slime')));
    await _settle(tester);
    expect(controller.progress.equippedIn(CosmeticSlot.poop), 'poop_slime');
    expect(controller.progress.coins, 0);
  });

  testWidgets('finishing a level shows the coins it earned', (tester) async {
    await _useLandscape(tester);
    final controller = _controller();
    await tester.pumpWidget(PoopyBirdApp(controller: controller));
    await _settle(tester);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suburbs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 10 && find.text('GO!').evaluate().isEmpty; i++) {
      await _settle(tester);
    }
    await tester.tap(find.text('GO!'));
    await tester.pump();

    final gameWidget = tester.widget<GameWidget<PoopyBirdGame>>(
        find.byType(GameWidget<PoopyBirdGame>));
    gameWidget.game!.finish(RunOutcome.crashed);
    await _settle(tester);

    expect(find.text('Crash!'), findsOneWidget);
    expect(controller.progress.recordFor('w1_l1').plays, 1);
    expect(find.byIcon(Icons.monetization_on_rounded), findsWidgets);
  });
}
