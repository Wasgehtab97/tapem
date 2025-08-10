import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

class MuscleChips extends StatelessWidget {
  final List<String> muscleGroupIds;
  const MuscleChips({super.key, required this.muscleGroupIds});

  Color _colorForRegion(MuscleRegion region, ThemeData theme) {
    switch (region) {
      case MuscleRegion.chest:
        return Colors.red.shade300;
      case MuscleRegion.back:
        return Colors.blue.shade300;
      case MuscleRegion.shoulders:
        return Colors.orange.shade300;
      case MuscleRegion.arms:
        return Colors.green.shade300;
      case MuscleRegion.core:
        return Colors.purple.shade300;
      case MuscleRegion.legs:
        return Colors.teal.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MuscleGroupProvider>();
    final groups = prov.groups
        .where((g) => muscleGroupIds.contains(g.id))
        .toList();
    if (groups.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final g in groups)
          Semantics(
            label: 'Muskelgruppe: ${g.name}',
            child: Chip(
              visualDensity: VisualDensity.compact,
              avatar: CircleAvatar(
                backgroundColor: _colorForRegion(g.region, theme),
                radius: 6,
              ),
              label: Text(g.name),
            ),
          ),
      ],
    );
  }
}
