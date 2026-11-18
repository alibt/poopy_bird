# Store release checklist

Bundle id: **`com.alibt.poopybird`** (Android `applicationId` + iOS
`PRODUCT_BUNDLE_IDENTIFIER`). Display name: **Poopy Bird**.

## Before the first store build

1. **AdMob**
   - Create an AdMob app for Android and iOS.
   - Replace the sample app ids in:
     - `android/app/src/main/AndroidManifest.xml`
       (`com.google.android.gms.ads.APPLICATION_ID`)
     - `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
     - `lib/monetization/live_config.dart` (`*AdMobAppIdProd`, `*RewardedUnitProd`)
   - Set `LiveConfig.useTestAds = false`.
2. **IAP**
   - Create products in App Store Connect / Play Console with ids:
     `coins_small`, `coins_medium`, `coins_large`, `remove_ads`, `starter_pack`.
   - Prices can differ per store; the shop shows the store price when the
     `in_app_purchase` query succeeds, otherwise the fallback labels.
3. **Signing**
   - Android: replace the debug `signingConfig` in `android/app/build.gradle`
     with a release keystore (do not commit the keystore).
   - iOS: set the team + provisioning in Xcode for `com.alibt.poopybird`.
4. **Consent**
   - Add Google UMP (User Messaging Platform) before loading ads in the EU/UK.
     Not wired yet; track as a follow-up before EU launch.
5. **Icons / splash**
   - Sources live in `assets/branding/`. Regenerate with:
     ```bash
     dart run flutter_launcher_icons
     dart run flutter_native_splash:create
     ```

## Listing copy (draft)

**Short description**  
You’re a bird. You poop on cars. Splat traffic, build combos, calm the rage
meter, and upgrade your belly across five chaotic worlds.

**Full description**  
Poopy Bird is a landscape arcade game built for quick runs.

- Campaign worlds with objectives and star ratings  
- Endless mode after you clear the Suburbs  
- Food power-ups, boss cars, cosmetics, and upgrades  
- Optional rewarded ads to double a run’s coins  
- Optional coin packs and Remove Ads  

Play offline. Progress saves on device.

**Keywords**  
arcade, bird, cars, casual, endless, landscape, comedy, splat

## Data safety / App Privacy (ads)

When ads are enabled the ads SDK may collect advertising id / device
identifiers. Declare that in Play Data safety and App Store privacy labels.
No account is required; progress is local until a backend sync lands.

## Build commands

```bash
flutter build appbundle --release
flutter build ipa --release
```

Version is `pubspec.yaml` → `1.0.0+1` (`versionName` / `CFBundleShortVersionString`
+ build number).
