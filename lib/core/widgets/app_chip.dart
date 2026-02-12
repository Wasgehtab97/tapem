import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';

/// Standardisiertes Chip-Widget für Filter/Tags in Owner/Report/Admin-Bereichen.
///
/// Unterstützt Selected/Unselected States mit Brand-Color für Auswahl.
/// Verwendet AppRadius.chip für konsistente Rundungen.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null
          ? Icon(
              icon,
              size: 18,
              color: selected ? brandColor : theme.colorScheme.onSurface.withOpacity(0.7),
            )
          : null,
      selectedColor: brandColor.withOpacity(0.2),
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: selected ? brandColor : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? brandColor
            : theme.colorScheme.onSurface.withOpacity(0.2),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

/// FilterChip-Variante für Multi-Select Filter.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null
          ? Icon(
              icon,
              size: 18,
              color: selected ? brandColor : theme.colorScheme.onSurface.withOpacity(0.7),
            )
          : null,
      selectedColor: brandColor.withOpacity(0.2),
      backgroundColor: theme.colorScheme.surface,
      checkmarkColor: brandColor,
      labelStyle: TextStyle(
        color: selected ? brandColor : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected
            ? brandColor
            : theme.colorScheme.onSurface.withOpacity(0.2),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }
}
