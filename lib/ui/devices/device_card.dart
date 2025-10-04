import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onAssignMuscles;
  final VoidCallback? onResetMuscles;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onAssignMuscles,
    this.onResetMuscles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = device.description;
    final idText = device.id.toString();
    final loc = AppLocalizations.of(context)!;
    final brandTheme = theme.extension<AppBrandTheme>();
    final brandColor = brandTheme?.outline ?? theme.colorScheme.secondary;
    final secondaryColor = theme.colorScheme.onSurface.withOpacity(0.7);
    final idColor = brandColor.withOpacity(0.85);

    final semanticsLabel =
        '${device.name}, ${brand.isNotEmpty ? '$brand, ' : ''}ID $idText';

    return BrandInteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      semanticLabel: semanticsLabel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: brandColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                if (brand.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                    child: Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ID: $idText',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: idColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (onAssignMuscles != null || onResetMuscles != null)
                      PopupMenuButton<_Menu>(
                        tooltip: loc.assignMuscleGroups,
                        icon: Icon(Icons.more_vert, color: brandColor),
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
                ),
                if (!device.isMulti &&
                    (device.primaryMuscleGroups.isNotEmpty ||
                        device.secondaryMuscleGroups.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MuscleChips(
                        primaryIds: device.primaryMuscleGroups,
                        secondaryIds: device.secondaryMuscleGroups,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Menu { assign, reset }

