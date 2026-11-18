import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/progress_controller.dart';
import '../../components/car.dart' show hueRotation;
import '../../economy/catalog.dart';
import '../../progress/player_progress.dart';
import '../widgets.dart';

/// Spend coins on upgrades and cosmetics.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return DefaultTabController(
      length: 2,
      child: SkyBackground(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Shop',
              trailing: CoinCount(coins: controller.progress.coins, size: 26),
            ),
            const TabBar(
              labelColor: brandBrown,
              indicatorColor: brandBrown,
              labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              tabs: [
                Tab(text: 'Upgrades', height: 36),
                Tab(text: 'Looks', height: 36)
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _Grid(children: [
                    for (final upgrade in Catalog.upgrades)
                      _UpgradeCard(upgrade: upgrade),
                  ]),
                  _Grid(children: [
                    for (final item in Catalog.cosmetics)
                      _CosmeticCard(item: item),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisExtent: 132,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }
}

/// Runs a shop action and reports a refusal instead of throwing.
Future<void> _attempt(
  BuildContext context,
  Future<void> Function(ProgressController) action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action(AppScope.read(context));
  } on ShopException catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(switch (e.error) {
        ShopError.notEnoughCoins => 'Not enough coins yet!',
        ShopError.maxedOut => 'Already maxed out.',
        ShopError.alreadyOwned => 'You already own that.',
        ShopError.notOwned || ShopError.unknownItem => 'Not available.',
      }),
    ));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandBrown, width: 2),
      ),
      child: child,
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton(
      {super.key,
      required this.price,
      required this.affordable,
      this.onPressed});

  final int price;
  final bool affordable;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(96, 36),
        backgroundColor: affordable ? brandYellow : Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded,
              size: 18, color: brandBrown),
          const SizedBox(width: 4),
          Text('$price', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.upgrade});

  final UpgradeDefinition upgrade;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final tier = progress.upgradeTier(upgrade.id);
    final cost = upgrade.nextCost(tier);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(upgrade.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: brandBrown)),
          Text(upgrade.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(
            cost == null
                ? upgrade.effectLabel(tier)
                : '${upgrade.effectLabel(tier)} → ${upgrade.effectLabel(tier + 1)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < upgrade.maxTier; i++)
                Container(
                  width: 18,
                  height: 6,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: i < tier ? coinGold : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              if (cost == null)
                const Text('MAX',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: brandBrown))
              else
                _PriceButton(
                  key: ValueKey('buy_${upgrade.id.id}'),
                  price: cost,
                  affordable: progress.coins >= cost,
                  onPressed: () =>
                      _attempt(context, (c) => c.buyUpgrade(upgrade.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CosmeticCard extends StatelessWidget {
  const _CosmeticCard({required this.item});

  final CosmeticDefinition item;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final owned = progress.owns(item.id);
    final equipped = progress.equippedIn(item.slot) == item.id;

    final Widget preview = switch (item.slot) {
      CosmeticSlot.plumage => ColorFiltered(
          colorFilter: hueRotation(item.birdHue),
          child:
              Image.asset('assets/images/bird_01.png', width: 56, height: 56),
        ),
      CosmeticSlot.poop => Container(
          width: 40,
          height: 40,
          decoration:
              BoxDecoration(color: item.poopColor, shape: BoxShape.circle),
        ),
    };

    return _Card(
      child: Row(
        children: [
          SizedBox(width: 60, child: Center(child: preview)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: brandBrown)),
                Text(
                  item.slot == CosmeticSlot.plumage ? 'Feathers' : 'Poop',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (equipped)
            const Icon(Icons.check_circle_rounded, color: Colors.green)
          else if (owned)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(80, 36)),
              onPressed: () => _attempt(context, (c) => c.equip(item.id)),
              child: const Text('Use'),
            )
          else
            _PriceButton(
              key: ValueKey('buy_${item.id}'),
              price: item.price,
              affordable: progress.coins >= item.price,
              onPressed: () => _attempt(context, (c) => c.buyCosmetic(item.id)),
            ),
        ],
      ),
    );
  }
}
