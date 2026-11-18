import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/progress_controller.dart';
import 'levels/level_repository.dart';
import 'monetization/ads.dart';
import 'progress/progress_repository.dart';
import 'settings/settings_store.dart';
import 'storage/shared_prefs_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final store = SharedPrefsStore();
  final controller = ProgressController(
    levelRepository: AssetLevelRepository(),
    progressRepository: LocalProgressRepository(store),
    settingsStore: SettingsStore(store),
    ads: kDebugMode ? const DebugRewardedAds() : const NoAds(),
  );
  runApp(PoopyBirdApp(controller: controller));
}
