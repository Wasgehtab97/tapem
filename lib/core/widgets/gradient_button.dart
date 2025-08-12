import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/brand_surface_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).extension<BrandSurfaceTheme>();
    final radius = surface?.radius ?? BorderRadius.circular(AppRadius.button);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: surface?.gradient ?? AppGradients.brandGradient,
        borderRadius: radius,
        boxShadow: surface?.shadow,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          textStyle: surface?.textStyle,
          minimumSize: Size.fromHeight(surface?.height ?? 40),
          padding: surface?.padding as EdgeInsets? ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
