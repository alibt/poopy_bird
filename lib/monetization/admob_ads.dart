import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads.dart';
import 'live_config.dart';

/// Google Mobile Ads rewarded implementation. Uses [LiveConfig] unit ids
/// (test ids by default). Safe to construct on any platform; [init] no-ops
/// off Android/iOS.
class AdMobRewardedAds implements RewardedAds {
  AdMobRewardedAds();

  bool _sdkReady = false;
  RewardedAd? _ad;
  bool _loading = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _sdkReady = true;
      await _preload();
    } catch (e, st) {
      _sdkReady = false;
      debugPrint('AdMob init failed: $e\n$st');
    }
  }

  Future<void> _preload() async {
    if (!_sdkReady || _loading || _ad != null) return;
    _loading = true;
    final done = Completer<void>();
    await RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          if (!done.isCompleted) done.complete();
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _ad = null;
          _loading = false;
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    await done.future;
  }

  @override
  bool isAvailable(AdPlacement placement) => _sdkReady && _ad != null;

  @override
  Future<bool> show(AdPlacement placement) async {
    final ad = _ad;
    if (ad == null) {
      await _preload();
      return false;
    }
    _ad = null;
    final rewarded = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!rewarded.isCompleted) rewarded.complete(false);
        _preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: $error');
        ad.dispose();
        if (!rewarded.isCompleted) rewarded.complete(false);
        _preload();
      },
    );
    ad.show(onUserEarnedReward: (_, __) {
      if (!rewarded.isCompleted) rewarded.complete(true);
    });
    return rewarded.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }

  static String get _rewardedUnitId {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    if (LiveConfig.useTestAds) {
      return ios
          ? LiveConfig.iosRewardedUnitTest
          : LiveConfig.androidRewardedUnitTest;
    }
    return ios
        ? LiveConfig.iosRewardedUnitProd
        : LiveConfig.androidRewardedUnitProd;
  }
}
