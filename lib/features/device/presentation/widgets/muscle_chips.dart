import 'package:flutter/material.dart';

import 'package:tapem/features/muscle_group/presentation/widgets/muscle_group_label_chip.dart';

class MuscleChips extends StatelessWidget {
  final List<String> muscleGroupIds;
  const MuscleChips({super.key, required this.muscleGroupIds});

  @override
  Widget build(BuildContext context) {
    if (muscleGroupIds.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final id in muscleGroupIds)
          MuscleGroupLabelChip(muscleGroupId: id),
      ],
    );
  }
}
