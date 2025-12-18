import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'muscle_group_color.dart';

class MuscleGroupCard extends StatelessWidget {
  final String muscleGroupId;
  const MuscleGroupCard({super.key, required this.muscleGroupId});

  @override
  Widget build(BuildContext context) {
    final prov = riverpod.ProviderScope.containerOf(context)
        .read(muscleGroupProvider);
    final group = prov.groups.firstWhere(
      (g) => g.id == muscleGroupId,
      orElse: () => MuscleGroup(id: '', name: '', region: MuscleRegion.bauch),
    );
    if (group.id.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    return Semantics(
      label: loc.a11yMgSelected(group.name),
      child: Chip(
        visualDensity: VisualDensity.compact,
        avatar: CircleAvatar(
          backgroundColor: colorForRegion(group.region),
          radius: 6,
        ),
        label: Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }
}
