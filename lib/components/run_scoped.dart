import 'package:flame/components.dart';

/// Marks components that belong to a single run (cars, poops, food, effects).
/// They are all removed when the game restarts.
mixin RunScoped on Component {}
