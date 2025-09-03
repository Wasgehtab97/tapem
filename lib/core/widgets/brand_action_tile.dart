import 'package:flutter/material.dart';

import 'brand_gradient_card.dart';
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
    final onGradient =
        Theme.of(context).extension<BrandOnColors>()?.onGradient ?? Colors.black;
    final titleStyle =
        variant == BrandActionTileVariant.gradient ? TextStyle(color: onGradient) : null;
    final subtitleStyle =
        variant == BrandActionTileVariant.gradient ? TextStyle(color: onGradient) : null;

    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      dense: dense,
      minVerticalPadding: minVerticalPadding,
      leading: leading ??
          (leadingIcon != null ? Icon(leadingIcon, color: onGradient) : null),
      title: Text(
        title,
        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
        style: titleStyle,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: subtitleStyle,
            )
          : null,
      trailing: showChevron
          ? (trailing ?? Icon(Icons.chevron_right, color: onGradient))
          : null,
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
