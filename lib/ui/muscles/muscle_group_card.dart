import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

import 'muscle_group_color.dart';

class MuscleGroupCard extends StatelessWidget {
  final String muscleGroupId;
  const MuscleGroupCard({super.key, required this.muscleGroupId});

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
