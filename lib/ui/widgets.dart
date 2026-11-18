import 'package:flutter/material.dart';

const Color _sky = Color(0xFF87CEEB);
const Color _skyLight = Color(0xFFD6F0FB);
const Color brandYellow = Color(0xFFFFC72C);
const Color brandBrown = Color(0xFF5D3A1A);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandYellow,
    primary: brandYellow,
    onPrimary: brandBrown,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brandYellow,
        foregroundColor: brandBrown,
        disabledBackgroundColor: Colors.white54,
        minimumSize: const Size(160, 48),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brandBrown,
        backgroundColor: Colors.white70,
        minimumSize: const Size(120, 44),
        side: const BorderSide(color: brandBrown, width: 2),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

/// Sky gradient used behind every menu screen.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_sky, _skyLight],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// A rounded card for menu content and in-game dialogs.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.maxWidth = 440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: brandBrown, width: 3),
        ),
        child: child,
      ),
    );
  }
}

/// A dark full-screen scrim with a centred, scrollable panel; used for the
/// in-game overlays.
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Panel(child: child),
        ),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 18});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? const Color(0xFFFFB300) : Colors.black26,
          ),
      ],
    );
  }
}

/// Back button + title + optional trailing widget, for menu screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: brandBrown,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "★ 12/27" badge.
class StarCount extends StatelessWidget {
  const StarCount({super.key, required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFB300)),
        Text(
          '$earned/$total',
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: brandBrown),
        ),
      ],
    );
  }
}

const Color coinGold = Color(0xFFFFB300);

/// "● 250" coin badge.
class CoinCount extends StatelessWidget {
  const CoinCount({super.key, required this.coins, this.size = 20});

  final int coins;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/coin.png',
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.monetization_on_rounded, color: coinGold, size: size),
        ),
        const SizedBox(width: 2),
        Text(
          '$coins',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: brandBrown,
            fontSize: size * 0.8,
          ),
        ),
      ],
    );
  }
}
