# Monetization and economy

Poopy Bird earns money from rewarded ads and in-app purchases (IAP). Both
feed the same soft currency, **coins**, which buy upgrades and cosmetics.
Nothing is pay-to-win only: every item can be bought with coins earned by
playing.

## Coins in (per run)

Rules live in `lib/economy/rewards.dart` (`RewardRules`). They are pure
code, so a backend can run the same rules to check a client's claim.

| Source | Coins |
|---|---|
| Level score | 1 per 100 points, max 60 |
| Winning a level | +10 |
| Each star earned for the first time on a level | +25 |
| First boss clear | +150 |
| Endless score | 1 per 80 points, max 150 |
| Rewarded ad on the results screen | doubles that run's coins |

A full 3-star World 1 pays about 825 coins in stars and bonuses, plus about
20 per play. That covers roughly a third of the upgrades.

## Coins out

Prices are in `lib/economy/catalog.dart`.

- **Upgrades** (6, three tiers each, about 5,300 coins for all):
  - Bigger Belly
  - Fast Digestion
  - Hot Sauce
  - Extra Beans
  - Combo Keeper
  - Zen Feathers
- **Cosmetics**:
  - Feather tints: 300–800 coins.
  - Poop colours: 250–1,200 coins.
  - Both are placeholder tints until the Blender art arrives (M5).

## Rewarded ads

| Placement | Where | Reward | Status |
|---|---|---|---|
| `double_coins` | Results screen | Run coins ×2 | Built, uses the debug fake |
| `continue` | Crash / rage-out | Revive once per run | Planned (M6) |
| `daily_bonus` | Main menu | +50 coins, once a day | Planned (M4, with daily rewards) |

- **Code**: the screens see only the `RewardedAds` interface (`lib/monetization/ads.dart`).
- **Debug builds**: use `DebugRewardedAds`, which pretends an ad was watched.
- **Release builds**: use `NoAds`, so the ad buttons are hidden until the SDK is added.

Rules:

- Ads are rewarded only. There are no interstitials during play.
- Players opt in to every ad.
- Ads are never shown before the first World 1 boss clear.

## In-app purchases (planned, M7)

| Product | Type | Contents |
|---|---|---|
| `coins_small` | Consumable | 1,000 coins |
| `coins_medium` | Consumable | 3,000 coins (+20%) |
| `coins_large` | Consumable | 8,000 coins (+60%) |
| `remove_ads` | Non-consumable | Hides ad buttons and doubles coins automatically |
| `starter_pack` | Non-consumable, one-time | 2,000 coins and the Golden poop |

## Integration steps (M7)

1. Add `google_mobile_ads` and implement `RewardedAds` with it. Turn on
   server-side verification (SSV) once the backend exists, so ad rewards are
   granted by the server and not the client.
2. Add `in_app_purchase` and an `IapStore` service.
   - Receipts are checked by the backend.
   - The client grants coins only after the server confirms, through
     `ProgressRepository.grantCoins(reason: 'iap:<orderId>')`.
3. Consent: show Google's UMP consent form (GDPR/CCPA) before loading any ads.
4. Store listings: complete the Data safety and App Privacy forms (the ads SDK
   collects device identifiers).

## Backend notes

- **Changes are named actions.** Progress changes are recorded as actions such
  as `record`, `buyUpgrade`, `buyCosmetic` and `grantCoins`; the app never
  overwrites the whole balance. A server can therefore check each change.
- **Outbox for sync.** `LocalProgressRepository` writes every action to an
  outbox, with a timestamp and a reason for each grant. A sync service can
  upload the outbox and replace the local balance with the server's.
- **Remote prices.** Prices are client constants for now. To tune them without
  an app release, serve them as remote config.
