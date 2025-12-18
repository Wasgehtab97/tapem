import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';

/// Small, animated flame badge that reacts to the active BrandTheme.
///
/// - Im Flame-Theme (AppBrandTheme.isFlame == true) zeigt der Badge
///   einen deutlich sichtbaren, aber hochwertigen Flackereffekt mit
///   pulsierendem Glow und leichtem Scale.
/// - In allen anderen Themes wird ein statischer, gebrandeter Badge
///   ohne Animation gerendert.
class FlameBadge extends StatefulWidget {
  const FlameBadge({
    super.key,
    required this.child,
    this.size = 56,
  });

  final Widget child;
  final double size;

  @override
  State<FlameBadge> createState() => _FlameBadgeState();
}

class _FlameBadgeState extends State<FlameBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final isFlame = brand?.isFlame ?? false;

    // Statischer Fallback für alle Nicht-Flame-Themes.
    if (!isFlame || brand == null) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.06),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: widget.child),
      );
    }

    final baseGradient = brand.gradient;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // Subtiles, aber deutlich sichtbares Pulsieren.
        final scale = 0.96 + t * 0.10;
        final glowOpacity = 0.55 + t * 0.35;

        final colors = [
          Color.lerp(baseGradient.colors.first, Colors.white, 0.06 * t) ??
              baseGradient.colors.first,
          Color.lerp(baseGradient.colors.last, Colors.black, 0.10 * (1 - t)) ??
              baseGradient.colors.last,
        ];

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(glowOpacity),
                  blurRadius: 22 + 8 * t,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(AppRadius.card - 4),
              ),
              child: Center(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

