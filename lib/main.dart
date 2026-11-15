import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/progress_controller.dart';
import 'levels/level_repository.dart';
import 'progress/progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Swap these for on-device (M3) or backend-backed implementations.
  final controller = ProgressController(
    levelRepository: AssetLevelRepository(),
    progressRepository: InMemoryProgressRepository(),
  );
  runApp(PoopyBirdApp(controller: controller));
}
