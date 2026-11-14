/// Food the bird can eat mid-flight.
enum FoodType {
  /// Refills some ammo.
  berries('Berries!', weight: 6),

  /// Rapid fire that costs no ammo, for a few seconds.
  chili('Chili! Rapid fire', weight: 2),

  /// The next few poops are big and splat nearby cars too.
  burrito('Burrito! Big poops', weight: 2);

  const FoodType(this.label, {required this.weight});

  final String label;

  /// Relative spawn chance.
  final int weight;

  /// Picks a food type at random, respecting [weight]s. [roll] is in [0, 1).
  static FoodType pick(double roll) {
    final total = values.fold<int>(0, (sum, f) => sum + f.weight);
    var target = roll * total;
    for (final food in values) {
      target -= food.weight;
      if (target < 0) return food;
    }
    return values.last;
  }
}
