import 'dart:ui' show Color;

import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';

ButtonStyle sessionActionButtonStyle(
  BuildContext context, {
  bool isActive = false,
  Color? foregroundColor,
}) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final brand = theme.extension<AppBrandTheme>();
  final primary = brand?.outline ?? colors.primary;
  final surfaceVariant = colors.surfaceVariant;
  final backgroundTint = primary.withOpacity(isActive ? 0.24 : 0.16);
  final background = Color.alphaBlend(backgroundTint, surfaceVariant);
  final disabledBackground = Color.alphaBlend(
    primary.withOpacity(0.08),
    surfaceVariant,
  );
  final resolvedForeground = foregroundColor ??
      (isActive ? colors.onPrimary : primary);

  return IconButton.styleFrom(
    backgroundColor: background,
    foregroundColor: resolvedForeground,
    disabledForegroundColor: colors.onSurface.withOpacity(0.38),
    disabledBackgroundColor: disabledBackground,
    padding: const EdgeInsets.all(8),
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size.square(40),
  ).copyWith(
    foregroundColor: WidgetStatePropertyAll(resolvedForeground),
    overlayColor: WidgetStateProperty.resolveWith<Color?>(
      (states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.pressed)) {
          return primary.withOpacity(0.20);
        }
        if (states.contains(WidgetState.hovered)) {
          return primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.focused)) {
          return primary.withOpacity(0.16);
        }
        return null;
      },
    ),
  );
}
