/// Store / AdMob / IAP ids. Test values ship by default; swap the production
/// constants before a store build (see docs/STORE.md).
abstract final class LiveConfig {
  /// Reverse-DNS application id (Android applicationId / iOS bundle id).
  static const String applicationId = 'com.alibt.poopybird';

  /// When true, use Google's official sample ad unit ids.
  static const bool useTestAds = true;

  // ── AdMob app ids (also duplicated in AndroidManifest / Info.plist) ─────
  static const String androidAdMobAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String iosAdMobAppId =
      'ca-app-pub-3940256099942544~1458002511';

  // Production placeholders — replace before release when [useTestAds] is false.
  static const String androidAdMobAppIdProd =
      'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY';
  static const String iosAdMobAppIdProd =
      'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY';

  static const String androidRewardedUnitTest =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosRewardedUnitTest =
      'ca-app-pub-3940256099942544/1712485313';
  static const String androidRewardedUnitProd =
      'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ';
  static const String iosRewardedUnitProd =
      'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ';

  // ── IAP product ids (must match App Store Connect / Play Console) ───────
  static const String coinsSmallId = 'coins_small';
  static const String coinsMediumId = 'coins_medium';
  static const String coinsLargeId = 'coins_large';
  static const String removeAdsId = 'remove_ads';
  static const String starterPackId = 'starter_pack';

  static const List<String> iapProductIds = [
    coinsSmallId,
    coinsMediumId,
    coinsLargeId,
    removeAdsId,
    starterPackId,
  ];
}
