import 'package:flutter/material.dart';

import 'brand_gradient_card.dart';
import 'brand_gradient_icon.dart';
import 'brand_gradient_text.dart';
import 'brand_outline.dart';
import '../theme/brand_on_colors.dart';
import '../theme/design_tokens.dart';
import '../logging/elog.dart';

/// Visual styles for [BrandActionTile].
enum BrandActionTileVariant {
  /// Filled card using the brand gradient.
  gradient,

  /// Outlined surface using the brand outline style.
  outlined,
}

/// Navigable tile using the brand gradient background or outlined surface.
class BrandActionTile extends StatelessWidget {
  final Widget? leading;
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool centerTitle;
  final bool showChevron;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool dense;
  final double? minVerticalPadding;
  final String? uiLogEvent;

  /// Visual variant of the tile.
  ///
  /// Defaults to [BrandActionTileVariant.gradient] to preserve existing
  /// behaviour. Use [BrandActionTileVariant.outlined] for a surface styled like
  /// the gym device cards.
  final BrandActionTileVariant variant;

  const BrandActionTile({
    super.key,
    this.leading,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.centerTitle = false,
    this.showChevron = true,
    this.margin,
    this.padding,
    this.dense = false,
    this.minVerticalPadding,
    this.variant = BrandActionTileVariant.gradient,
    this.uiLogEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (uiLogEvent != null) {
      elogUi(uiLogEvent!, {'title': title});
    }
    final theme = Theme.of(context);
    final onGradient =
        theme.extension<BrandOnColors>()?.onGradient ?? Colors.black;
    final defaultTitleStyle = theme.textTheme.titleMedium;
    final defaultSubtitleStyle = theme.textTheme.bodyMedium;

    final Widget titleWidget = variant == BrandActionTileVariant.gradient
        ? Text(
            title,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: TextStyle(color: onGradient),
          )
        : BrandGradientText(
            title,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: defaultTitleStyle,
          );

    final Widget? subtitleWidget = subtitle != null
        ? (variant == BrandActionTileVariant.gradient
            ? Text(
                subtitle!,
                style: TextStyle(color: onGradient),
              )
            : BrandGradientText(
                subtitle!,
                style: defaultSubtitleStyle,
              ))
        : null;

    final Widget? leadingWidget = leading ??
        (leadingIcon != null
            ? (variant == BrandActionTileVariant.gradient
                ? Icon(leadingIcon, color: onGradient)
                : BrandGradientIcon(leadingIcon!))
            : null);

    final Widget? trailingWidget = showChevron
        ? (trailing ??
            (variant == BrandActionTileVariant.gradient
                ? Icon(Icons.chevron_right, color: onGradient)
                : const BrandGradientIcon(Icons.chevron_right)))
        : trailing;

    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      dense: dense,
      minVerticalPadding: minVerticalPadding,
      leading: leadingWidget,
      title: titleWidget,
      subtitle: subtitleWidget,
      trailing: trailingWidget,
    );

    final Widget card = variant == BrandActionTileVariant.gradient
        ? BrandGradientCard(onTap: onTap, padding: padding, child: tile)
        : BrandOutline(
            onTap: onTap,
            padding: padding ?? const EdgeInsets.all(AppSpacing.sm),
            child: tile,
          );

    return Container(
      margin: margin,
      child: card,
    );
  }
}
