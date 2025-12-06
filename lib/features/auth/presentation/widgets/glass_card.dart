import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/auth_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? AuthTheme.glassBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AuthTheme.glassBlur,
            sigmaY: AuthTheme.glassBlur,
          ),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AuthTheme.spacingL),
            decoration: BoxDecoration(
              color: AuthTheme.glassColor,
              borderRadius: BorderRadius.circular(borderRadius ?? AuthTheme.glassBorderRadius),
              border: Border.all(
                color: AuthTheme.glassBorderColor,
                width: 1.0,
              ),
              boxShadow: [AuthTheme.softShadow],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
