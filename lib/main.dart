import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/progress_controller.dart';
import 'levels/level_repository.dart';
import 'monetization/monetization.dart';
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
  final progressRepository = LocalProgressRepository(store);
  final progress = await progressRepository.load();

  final monetization = await Monetization.create(removeAds: progress.removeAds);

  final controller = ProgressController(
    levelRepository: AssetLevelRepository(),
    progressRepository: progressRepository,
    settingsStore: SettingsStore(store),
    ads: monetization.ads,
    iap: monetization.iap,
  );
  // Progress is loaded again inside controller.load(); that is fine.
  runApp(PoopyBirdApp(controller: controller));
}
