import 'package:flutter/widgets.dart';

import 'progress_controller.dart';

/// Makes the [ProgressController] available to every screen and rebuilds
/// dependents when progress changes.
class AppScope extends InheritedNotifier<ProgressController> {
  const AppScope({
    super.key,
    required ProgressController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProgressController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the controller without rebuilding when it changes.
  static ProgressController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
