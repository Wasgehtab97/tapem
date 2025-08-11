import 'package:flutter/material.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/presentation/widgets/muscle_chips.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final List<MuscleGroup>? groupsForDevice;
  final VoidCallback? onTap;
  const DeviceCard({super.key, required this.device, this.groupsForDevice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = device.description;
    final idText = device.id.toString();
    final muscleIds = [
      ...device.primaryMuscleGroups,
      ...device.secondaryMuscleGroups,
    ];
    return Semantics(
      label: '${device.name}, ${brand.isNotEmpty ? '$brand, ' : ''}ID $idText',
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap?.call(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style: theme.textTheme.titleMedium,
                      ),
                      if (brand.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('ID: $idText', style: theme.textTheme.labelSmall),
                      if (!device.isMulti && muscleIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: MuscleChips(muscleGroupIds: muscleIds),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

