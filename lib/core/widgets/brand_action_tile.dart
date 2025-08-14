import 'package:flutter/material.dart';

import 'brand_gradient_card.dart';

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
    return BrandGradientCard(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: leading ?? (leadingIcon != null ? Icon(leadingIcon) : null),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
