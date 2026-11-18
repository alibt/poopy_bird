import 'package:flutter/material.dart';

import '../ui/achievement_toast.dart';
import '../ui/screens/main_menu_screen.dart';
import '../ui/widgets.dart';
import 'app_scope.dart';
import 'progress_controller.dart';

class PoopyBirdApp extends StatefulWidget {
  const PoopyBirdApp({super.key, required this.controller});

  final ProgressController controller;

  @override
  State<PoopyBirdApp> createState() => _PoopyBirdAppState();
}

class _PoopyBirdAppState extends State<PoopyBirdApp> {
  late final Future<void> _loading = widget.controller.load();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: widget.controller,
      child: MaterialApp(
        title: 'Poopy Bird',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => AchievementToastHost(
          controller: widget.controller,
          child: child!,
        ),
        home: FutureBuilder<void>(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SkyBackground(
                child: Center(
                  child: Panel(
                      child:
                          Text('Could not load the game:\n${snapshot.error}')),
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const SkyBackground(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const MainMenuScreen();
          },
        ),
      ),
    );
  }
}
