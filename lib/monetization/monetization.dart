import 'package:flutter/foundation.dart';

import 'admob_ads.dart';
import 'ads.dart';
import 'iap.dart';

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Picks platform-appropriate ads + IAP for this process.
class Monetization {
  Monetization._(this.ads, this.iap, this._adMob);

  final RewardedAds ads;
  final IapStore iap;
  final AdMobRewardedAds? _adMob;

  static Future<Monetization> create({required bool removeAds}) async {
    if (removeAds) {
      final iap = await _createIap();
      return Monetization._(const NoAds(), iap, null);
    }

    if (!_isMobile) {
      final ads = kDebugMode ? const DebugRewardedAds() : const NoAds();
      final iap = kDebugMode ? DebugIapStore() : const NoIapStore();
      await iap.init();
      return Monetization._(ads, iap, null);
    }

    final adMob = AdMobRewardedAds();
    await adMob.init();
    // Debug builds keep the instant fake so UI can be tested without an ad
    // fill; release uses the real SDK (still on Google test unit ids until
    // LiveConfig.useTestAds is flipped).
    final RewardedAds ads = kDebugMode ? const DebugRewardedAds() : adMob;
    final iap = kDebugMode ? DebugIapStore() : PlatformIapStore();
    await iap.init();
    return Monetization._(ads, iap, kDebugMode ? adMob : null);
  }

  static Future<IapStore> _createIap() async {
    final iap = !_isMobile
        ? (kDebugMode ? DebugIapStore() : const NoIapStore())
        : (kDebugMode ? DebugIapStore() : PlatformIapStore());
    await iap.init();
    return iap;
  }

  /// Rebuild ads when the player buys Remove Ads.
  Monetization withoutAds() {
    _adMob?.dispose();
    return Monetization._(const NoAds(), iap, null);
  }

  void dispose() {
    _adMob?.dispose();
    iap.dispose();
  }
}
