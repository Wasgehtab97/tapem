import 'package:flutter/material.dart';
import '../theme/app_brand_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/brand_on_colors.dart';

/// Reusable card container with the brand gradient and rounded corners.
class BrandGradientCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;

  const BrandGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<BrandGradientCard> createState() => _BrandGradientCardState();
}

class _BrandGradientCardState extends State<BrandGradientCard> {
  bool _isPressed = false;

  void _handleHighlightChanged(bool isPressed) {
    if (_isPressed != isPressed) {
      setState(() {
        _isPressed = isPressed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.extension<AppBrandTheme>();
    final BorderRadius radius =
        (widget.borderRadius ?? surface?.radius ?? BorderRadius.circular(AppRadius.card))
            as BorderRadius;
    final gradient = surface?.gradient ?? AppGradients.brandGradient;
    final shadow = surface?.shadow;
    final overlay = surface?.pressedOverlay ?? Colors.black26;
    final onBrand =
        Theme.of(context).extension<BrandOnColors>()?.onGradient ??
            Colors.black;

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: shadow,
      ),
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.sm),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: onBrand),
        child: IconTheme(
          data: IconThemeData(color: onBrand),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHighlightChanged: _handleHighlightChanged,
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return overlay.withOpacity(0.6);
            }
            if (states.contains(MaterialState.hovered)) {
              return overlay.withOpacity(0.3);
            }
            return overlay.withOpacity(0.15);
          }),
          splashFactory: InkRipple.splashFactory,
          child: content,
        ),
      );
    }

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: content,
    );
  }
}

/// Gradient header used for expansion tiles.
class BrandGradientHeader extends StatelessWidget {
  final Widget child;
  final bool expanded;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const BrandGradientHeader({
    super.key,
    required this.child,
    this.expanded = false,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<AppBrandTheme>();
    final baseRadius = surface?.radius as BorderRadius? ?? BorderRadius.circular(AppRadius.card);
    final radius = expanded
        ? BorderRadius.only(topLeft: baseRadius.topLeft, topRight: baseRadius.topRight)
        : baseRadius;
    return BrandGradientCard(
      borderRadius: radius,
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      onTap: onTap,
      child: child,
    );
  }
}
