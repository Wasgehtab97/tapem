import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';

class PremiumActionTile extends StatelessWidget {
  const PremiumActionTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.accentColor,
    this.trailingColor,
    this.trailing,
    this.trailingLeading,
    this.showArrow = true,
    this.margin,
    this.padding,
    this.borderRadius,
    this.gradient,
    this.bottom,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? accentColor;
  final Color? trailingColor;
  final Widget? trailing;
  final Widget? trailingLeading;
  final bool showArrow;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final LinearGradient? gradient;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = accentColor ?? brand?.outline ?? theme.colorScheme.secondary;
    final arrowColor = trailingColor ?? accent;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.cardLg);

    final trailingWidget =
        trailing ?? (showArrow ? _TileArrowBadge(color: arrowColor) : null);

    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      child: BrandInteractiveCard(
        onTap: onTap,
        onLongPress: onLongPress,
        padding: EdgeInsets.zero,
        borderRadius: radius,
        showShadow: false,
        showPressedOverlay: false,
        enableScaleAnimation: onTap != null || onLongPress != null,
        restingBorderColor: Colors.white.withOpacity(0.06),
        activeBorderColor: Colors.white.withOpacity(0.14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.scaffoldBackgroundColor.withOpacity(0.36),
                    theme.scaffoldBackgroundColor.withOpacity(0.24),
                  ],
                ),
          ),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accent.withOpacity(0.18),
                            accent.withOpacity(0.04),
                          ],
                          center: Alignment.topLeft,
                        ),
                      ),
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(color: accent, size: 20),
                          child: leading,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailingLeading != null) ...[
                      trailingLeading!,
                      if (trailingWidget != null) const SizedBox(width: 8),
                    ],
                    if (trailingWidget != null) trailingWidget,
                  ],
                ),
                if (bottom != null) ...[const SizedBox(height: 10), bottom!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TileArrowBadge extends StatelessWidget {
  const _TileArrowBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.35),
        border: Border.all(color: color.withOpacity(0.24), width: 1),
      ),
      child: Center(
        child: Icon(Icons.arrow_outward_rounded, color: color, size: 16),
      ),
    );
  }
}
