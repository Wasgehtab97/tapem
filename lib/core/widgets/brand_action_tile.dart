import 'package:flutter/material.dart';

import 'brand_gradient_card.dart';
import '../theme/brand_on_colors.dart';

/// Navigable tile using the brand gradient background.
class BrandActionTile extends StatelessWidget {
  final Widget? leading;
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const BrandActionTile({
    super.key,
    this.leading,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onGradient =
        Theme.of(context).extension<BrandOnColors>()?.onGradient ?? Colors.black;
    return BrandGradientCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: leading ??
            (leadingIcon != null
                ? Icon(leadingIcon, color: onGradient)
                : null),
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: Colors.black),
              )
            : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: onGradient),
      ),
    );
  }
}
