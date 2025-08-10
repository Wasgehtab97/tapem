import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/muscle_group.dart';
import '../../../../core/providers/muscle_group_provider.dart';
import 'muscle_group_color.dart';

class MuscleGroupLabelChip extends StatelessWidget {
  final String muscleGroupId;
  const MuscleGroupLabelChip({super.key, required this.muscleGroupId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MuscleGroupProvider>();
    final group = prov.groups.firstWhere(
      (g) => g.id == muscleGroupId,
      orElse: () => MuscleGroup(id: '', name: '', region: MuscleRegion.core),
    );
    if (group.id.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Semantics(
      label: 'Muskelgruppe: ${group.name}',
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: CircleAvatar(
          backgroundColor: colorForRegion(group.region, theme),
          radius: 6,
        ),
        label: Text(group.name),
      ),
    );
  }
}
