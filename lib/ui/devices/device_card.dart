import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAssignMuscles;
  final VoidCallback? onResetMuscles;
  final Widget? quickAction;
  final Widget? extraBottom;
  final String? muscleSummaryText;
  final EdgeInsetsGeometry? margin;
  final bool isFavorite;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onLongPress,
    this.onAssignMuscles,
    this.onResetMuscles,
    this.quickAction,
    this.extraBottom,
    this.muscleSummaryText,
    this.margin,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = device.description;
    final idText = device.id.toString();
    final loc = AppLocalizations.of(context)!;
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;

    final semanticsLabel =
        '${device.name}, ${brand.isNotEmpty ? '$brand, ' : ''}ID $idText';

    final trailingMeta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFavorite) ...[
          Icon(
            Icons.star_rounded,
            size: 18,
            color: brandColor.withOpacity(0.9),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brandColor.withOpacity(0.2), width: 1),
          ),
          child: Text(
            'ID: $idText',
            style: theme.textTheme.labelSmall?.copyWith(
              color: brandColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (quickAction != null) ...[const SizedBox(width: 6), quickAction!],
        if (onAssignMuscles != null || onResetMuscles != null)
          PopupMenuButton<_Menu>(
            tooltip: loc.assignMuscleGroups,
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
            padding: const EdgeInsets.only(left: 2),
            constraints: const BoxConstraints(),
            onSelected: (v) {
              switch (v) {
                case _Menu.assign:
                  onAssignMuscles?.call();
                  break;
                case _Menu.reset:
                  onResetMuscles?.call();
                  break;
              }
            },
            itemBuilder: (ctx) => [
              if (onAssignMuscles != null)
                PopupMenuItem(
                  value: _Menu.assign,
                  child: Text(loc.assignMuscleGroups),
                ),
              if (onResetMuscles != null)
                PopupMenuItem(
                  value: _Menu.reset,
                  child: Text(loc.resetMuscleGroups),
                ),
            ],
          ),
      ],
    );

    final hasMuscles =
        device.primaryMuscleGroups.isNotEmpty ||
        device.secondaryMuscleGroups.isNotEmpty;
    final baseBottom = !device.isMulti && hasMuscles
        ? (muscleSummaryText != null && muscleSummaryText!.trim().isNotEmpty
              ? _SimpleMuscleSummary(text: muscleSummaryText!)
              : MuscleChips(
                  primaryIds: device.primaryMuscleGroups,
                  secondaryIds: device.secondaryMuscleGroups,
                ))
        : null;
    final bottom = switch ((baseBottom, extraBottom)) {
      (null, null) => null,
      (final Widget only, null) => only,
      (null, final Widget only) => only,
      (final Widget base, final Widget extra) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [base, const SizedBox(height: 8), extra],
      ),
    };

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: PremiumActionTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Icon(
          device.isMulti ? Icons.hub_rounded : Icons.fitness_center_rounded,
        ),
        title: device.name,
        subtitle: brand.isNotEmpty ? brand : null,
        accentColor: brandColor,
        trailingLeading: trailingMeta,
        margin: margin,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        bottom: bottom,
      ),
    );
  }
}

enum _Menu { assign, reset }

class _SimpleMuscleSummary extends StatelessWidget {
  const _SimpleMuscleSummary({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.68),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
    );
  }
}
