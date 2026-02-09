import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';
import 'brand_interactive_card.dart';

/// Shared premium modal surface used by dialogs and bottom sheets.
class BrandModalSurface extends StatelessWidget {
  const BrandModalSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.borderRadius,
    this.gradient,
    this.shadow,
    this.border,
    this.blurSigma = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final Gradient? gradient;
  final BoxShadow? shadow;
  final BorderSide? border;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.cardLg);
    final borderSide =
        border ?? BorderSide(color: Colors.white.withOpacity(0.08), width: 1);
    final shadowStyle =
        shadow ??
        BoxShadow(
          color: Colors.black.withOpacity(0.55),
          blurRadius: 30,
          offset: const Offset(0, 18),
        );
    final gradientStyle =
        gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E).withOpacity(0.92),
            const Color(0xFF0F0F0F).withOpacity(0.96),
          ],
        );

    return Container(
      decoration: BoxDecoration(
        gradient: gradientStyle,
        borderRadius: radius,
        boxShadow: [shadowStyle],
        border: Border.fromBorderSide(borderSide),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Shared header used on premium modals.
class BrandModalHeader extends StatelessWidget {
  const BrandModalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.onClose,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onClose;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor =
        accent ?? brandTheme?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                accentColor.withOpacity(0.95),
                accentColor.withOpacity(0.4),
                accentColor.withOpacity(0.95),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.85),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: onSurface.withOpacity(0.7)),
          ),
      ],
    );
  }
}

/// Shared option card style used by modal action lists.
class BrandModalOptionCard extends StatelessWidget {
  const BrandModalOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent,
    this.highlighted = false,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accent;
  final bool highlighted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final accentColor =
        accent ?? brandTheme?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    final highlight = highlighted
        ? accentColor.withOpacity(0.18)
        : Colors.white.withOpacity(0.04);

    return BrandInteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      enableScaleAnimation: true,
      showShadow: false,
      backgroundColor: highlight,
      restingBorderColor: onSurface.withOpacity(0.08),
      activeBorderColor: accentColor.withOpacity(0.45),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.85),
                  accentColor.withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.arrow_forward_rounded,
                color: onSurface.withOpacity(0.6),
              ),
        ],
      ),
    );
  }
}

/// Consistent bottom sheet scaffold using the premium modal surface.
class BrandModalSheet extends StatelessWidget {
  const BrandModalSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 24),
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 12),
    this.showHandle = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: BrandModalSurface(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
