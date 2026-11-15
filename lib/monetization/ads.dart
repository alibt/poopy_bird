import 'package:flutter/foundation.dart';

/// Where a rewarded ad is offered. Stable ids, used for analytics and for
/// server-side reward verification later.
enum AdPlacement {
  /// Results screen: watch an ad to double the coins from that run.
  doubleCoins('double_coins');

  const AdPlacement(this.id);

  final String id;
}

/// Rewarded video ads. The real implementation (Google Mobile Ads, see
/// docs/MONETIZATION.md) plugs in here; screens only see this interface.
abstract interface class RewardedAds {
  /// Whether an ad can be shown right now. The UI hides ad buttons when
  /// false.
  bool isAvailable(AdPlacement placement);

  /// Shows an ad. Completes with true only if the player watched it to the
  /// end and earned the reward.
  Future<bool> show(AdPlacement placement);
}

/// No ads, e.g. before the SDK is integrated or after "Remove ads".
class NoAds implements RewardedAds {
  const NoAds();

  @override
  bool isAvailable(AdPlacement placement) => false;

  @override
  Future<bool> show(AdPlacement placement) async => false;
}

/// Pretends an ad was watched, so the reward flow can be tested in debug
/// builds. Never used in release.
class DebugRewardedAds implements RewardedAds {
  const DebugRewardedAds({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;

  @override
  bool isAvailable(AdPlacement placement) => kDebugMode;

  @override
  Future<bool> show(AdPlacement placement) async {
    await Future<void>.delayed(delay);
    return kDebugMode;
  }
}
