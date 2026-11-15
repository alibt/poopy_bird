import 'dart:ui' show Color;

import '../game/config.dart';

/// Gameplay upgrades, bought in tiers with coins.
///
/// Ids are stable strings because they are stored in player progress and,
/// later, validated by the backend. Never rename one; add a new id instead.
enum UpgradeId {
  belly('belly'),
  digestion('digestion'),
  chili('chili'),
  burrito('burrito'),
  combo('combo'),
  calm('calm');

  const UpgradeId(this.id);

  final String id;

  static UpgradeId? parse(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

class UpgradeDefinition {
  const UpgradeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.costs,
    required this.effectLabel,
  });

  final UpgradeId id;
  final String name;
  final String description;

  /// Price of each tier; tier 1 costs `costs[0]`. Its length is the max tier.
  final List<int> costs;

  /// Describes the effect at a tier (0 = not bought), e.g. "7 poops".
  final String Function(int tier) effectLabel;

  int get maxTier => costs.length;

  /// Price of the next tier after [tier], or null if maxed.
  int? nextCost(int tier) => tier < maxTier ? costs[tier] : null;
}

/// Cosmetic slots. A player equips at most one item per slot.
enum CosmeticSlot { plumage, poop }

/// A cosmetic item. Placeholder looks (tints) until the Blender art in M5.
class CosmeticDefinition {
  const CosmeticDefinition({
    required this.id,
    required this.slot,
    required this.name,
    required this.price,
    this.birdHue = 0,
    this.poopColor = defaultPoopColor,
  });

  final String id;
  final CosmeticSlot slot;
  final String name;

  /// 0 means free and owned from the start.
  final int price;

  /// Hue rotation applied to the bird, in degrees ([CosmeticSlot.plumage]).
  final double birdHue;

  /// Colour of poop and splats ([CosmeticSlot.poop]).
  final Color poopColor;

  bool get isFree => price == 0;
}

const Color defaultPoopColor = Color(0xFF6B4423);

/// Everything the shop sells. Kept in code because upgrade effects are
/// code; prices could later come from the backend (remote config).
abstract final class Catalog {
  static final List<UpgradeDefinition> upgrades = [
    UpgradeDefinition(
      id: UpgradeId.belly,
      name: 'Bigger Belly',
      description: 'Carry more poops.',
      costs: const [150, 400, 900],
      effectLabel: (t) => '${Loadout.bellyCapacityFor(t)} poops',
    ),
    UpgradeDefinition(
      id: UpgradeId.digestion,
      name: 'Fast Digestion',
      description: 'Refill your belly faster.',
      costs: const [120, 350, 800],
      effectLabel: (t) =>
          '1 poop / ${Loadout.digestionIntervalFor(t).toStringAsFixed(1)}s',
    ),
    UpgradeDefinition(
      id: UpgradeId.chili,
      name: 'Hot Sauce',
      description: 'Chili rapid fire lasts longer.',
      costs: const [100, 300, 700],
      effectLabel: (t) =>
          '${Loadout.chiliDurationFor(t).toStringAsFixed(1)}s rapid fire',
    ),
    UpgradeDefinition(
      id: UpgradeId.burrito,
      name: 'Extra Beans',
      description: 'Burritos give more big poops.',
      costs: const [100, 300, 700],
      effectLabel: (t) => '${Loadout.burritoBigPoopsFor(t)} big poops',
    ),
    UpgradeDefinition(
      id: UpgradeId.combo,
      name: 'Combo Keeper',
      description: 'More time to chain splats.',
      costs: const [150, 400, 900],
      effectLabel: (t) =>
          '${Loadout.comboWindowFor(t).toStringAsFixed(1)}s combo window',
    ),
    UpgradeDefinition(
      id: UpgradeId.calm,
      name: 'Zen Feathers',
      description: 'Escaping cars anger the city less.',
      costs: const [200, 500, 1000],
      effectLabel: (t) =>
          '${(Loadout.rageFillScaleFor(t) * 100).round()}% rage per escape',
    ),
  ];

  static const List<CosmeticDefinition> cosmetics = [
    CosmeticDefinition(
        id: 'plumage_classic',
        slot: CosmeticSlot.plumage,
        name: 'Classic',
        price: 0),
    CosmeticDefinition(
        id: 'plumage_mint',
        slot: CosmeticSlot.plumage,
        name: 'Mint',
        price: 300,
        birdHue: 120),
    CosmeticDefinition(
        id: 'plumage_royal',
        slot: CosmeticSlot.plumage,
        name: 'Royal',
        price: 500,
        birdHue: 220),
    CosmeticDefinition(
        id: 'plumage_flamingo',
        slot: CosmeticSlot.plumage,
        name: 'Flamingo',
        price: 800,
        birdHue: 300),
    CosmeticDefinition(
        id: 'poop_classic', slot: CosmeticSlot.poop, name: 'Classic', price: 0),
    CosmeticDefinition(
        id: 'poop_slime',
        slot: CosmeticSlot.poop,
        name: 'Slime',
        price: 250,
        poopColor: Color(0xFF7CB342)),
    CosmeticDefinition(
        id: 'poop_berry',
        slot: CosmeticSlot.poop,
        name: 'Berry Blast',
        price: 400,
        poopColor: Color(0xFF8E24AA)),
    CosmeticDefinition(
        id: 'poop_gold',
        slot: CosmeticSlot.poop,
        name: 'Golden',
        price: 1200,
        poopColor: Color(0xFFFFB300)),
  ];

  static UpgradeDefinition upgrade(UpgradeId id) =>
      upgrades.firstWhere((u) => u.id == id);

  static CosmeticDefinition? cosmetic(String id) {
    for (final item in cosmetics) {
      if (item.id == id) return item;
    }
    return null;
  }

  static CosmeticDefinition defaultFor(CosmeticSlot slot) =>
      cosmetics.firstWhere((c) => c.slot == slot && c.isFree);
}

/// The stats and looks a run is played with, built from the player's
/// upgrades and equipped cosmetics. The game reads only this, never the
/// player's progress.
class Loadout {
  const Loadout({
    this.upgrades = const {},
    this.plumage = 'plumage_classic',
    this.poop = 'poop_classic',
  });

  /// Tier per upgrade; missing means tier 0.
  final Map<UpgradeId, int> upgrades;
  final String plumage;
  final String poop;

  int tier(UpgradeId id) => upgrades[id] ?? 0;

  static int bellyCapacityFor(int tier) => GameConfig.bellyCapacity + tier;
  static double digestionIntervalFor(int tier) =>
      GameConfig.digestionInterval - 0.4 * tier;
  static double chiliDurationFor(int tier) =>
      GameConfig.chiliDuration + 1.5 * tier;
  static int burritoBigPoopsFor(int tier) => GameConfig.burritoBigPoops + tier;
  static double comboWindowFor(int tier) => GameConfig.comboWindow + 0.5 * tier;
  static double rageFillScaleFor(int tier) => 1 - 0.1 * tier;

  int get bellyCapacity => bellyCapacityFor(tier(UpgradeId.belly));
  double get digestionInterval =>
      digestionIntervalFor(tier(UpgradeId.digestion));
  double get chiliDuration => chiliDurationFor(tier(UpgradeId.chili));
  int get burritoBigPoops => burritoBigPoopsFor(tier(UpgradeId.burrito));
  double get comboWindow => comboWindowFor(tier(UpgradeId.combo));
  double get rageFillScale => rageFillScaleFor(tier(UpgradeId.calm));

  double get birdHue => Catalog.cosmetic(plumage)?.birdHue ?? 0;
  Color get poopColor => Catalog.cosmetic(poop)?.poopColor ?? defaultPoopColor;
}
