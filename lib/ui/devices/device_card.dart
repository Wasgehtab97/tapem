import 'package:flutter/material.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
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
    
    // Premium colors
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final idBadgeColor = brandColor.withOpacity(0.15);
    final idTextColor = brandColor;

    final semanticsLabel =
        '${device.name}, ${brand.isNotEmpty ? '$brand, ' : ''}ID $idText';

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  brandColor.withOpacity(0.08),
                  brandColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
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
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: idBadgeColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: brandColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ID: $idText',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: idTextColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (onAssignMuscles != null || onResetMuscles != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: PopupMenuButton<_Menu>(
                              tooltip: loc.assignMuscleGroups,
                              icon: Icon(
                                Icons.more_vert,
                                color: subtitleColor,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
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
                          ),
                      ],
                    ),
                    if (!device.isMulti &&
                        (device.primaryMuscleGroups.isNotEmpty ||
                            device.secondaryMuscleGroups.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: MuscleChips(
                          primaryIds: device.primaryMuscleGroups,
                          secondaryIds: device.secondaryMuscleGroups,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Menu { assign, reset }
