import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

class MuscleChips extends StatelessWidget {
  final List<String> primaryIds;
  final List<String> secondaryIds;
  const MuscleChips({super.key, required this.primaryIds, required this.secondaryIds});

  String _fallbackName(MuscleRegion region) {
    switch (region) {
      case MuscleRegion.chest:
        return 'Chest';
      case MuscleRegion.anteriorDeltoid:
        return 'Anterior Deltoid';
      case MuscleRegion.biceps:
        return 'Biceps';
      case MuscleRegion.wristFlexors:
        return 'Wrist Flexors';
      case MuscleRegion.lats:
        return 'Lats';
      case MuscleRegion.midBack:
        return 'Mid Back';
      case MuscleRegion.posteriorDeltoid:
        return 'Posterior Deltoid';
      case MuscleRegion.upperTrapezius:
        return 'Upper Trapezius';
      case MuscleRegion.triceps:
        return 'Triceps';
      case MuscleRegion.rectusAbdominis:
        return 'Rectus Abdominis';
      case MuscleRegion.obliques:
        return 'Obliques';
      case MuscleRegion.transversusAbdominis:
        return 'Transversus Abdominis';
      case MuscleRegion.quadriceps:
        return 'Quadriceps';
      case MuscleRegion.hamstrings:
        return 'Hamstrings';
      case MuscleRegion.glutes:
        return 'Glutes';
      case MuscleRegion.adductors:
        return 'Adductors';
      case MuscleRegion.abductors:
        return 'Abductors';
      case MuscleRegion.calves:
        return 'Calves';
      case MuscleRegion.tibialisAnterior:
        return 'Tibialis Anterior';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (primaryIds.isEmpty && secondaryIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final groups = context.watch<MuscleGroupProvider>().groups;

    MuscleRegion regionFor(String id, MuscleGroup? g) {
      if (g != null) return g.region;
      return MuscleRegion.values.firstWhereOrNull((r) => r.name == id) ?? MuscleRegion.rectusAbdominis;
    }

    String nameFor(String id) {
      final g = groups.firstWhereOrNull((e) => e.id == id);
      final region = regionFor(id, g);
      if (g != null && g.name.trim().isNotEmpty) return g.name;
      return _fallbackName(region);
    }

    Widget buildChip(String id, bool primary) {
      final name = nameFor(id);
      final color = primary ? theme.colorScheme.primary : theme.colorScheme.tertiary;
      final textColor = primary ? theme.colorScheme.onPrimary : theme.colorScheme.tertiary;
      return Semantics(
        label: '$name, ${primary ? 'primär' : 'sekundär'}',
        child: Chip(
          visualDensity: VisualDensity.compact,
          backgroundColor: primary ? color : Colors.transparent,
          shape: primary ? null : StadiumBorder(side: BorderSide(color: color)),
          label: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final id in primaryIds) buildChip(id, true),
        for (final id in secondaryIds) buildChip(id, false),
      ],
    );
  }
}
