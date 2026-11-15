import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/progress_controller.dart';
import 'levels/level_repository.dart';
import 'monetization/ads.dart';
import 'progress/progress_repository.dart';
import 'storage/shared_prefs_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Swap these for backend-backed implementations later; the screens and
  // the game only see the interfaces.
  final controller = ProgressController(
    levelRepository: AssetLevelRepository(),
    progressRepository: LocalProgressRepository(SharedPrefsStore()),
    // Real ads arrive with the SDK integration (docs/MONETIZATION.md).
    ads: kDebugMode ? const DebugRewardedAds() : const NoAds(),
  );
  runApp(PoopyBirdApp(controller: controller));
}
