import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';

class MuscleChips extends StatelessWidget {
  final List<String> primaryIds;
  final List<String> secondaryIds;
  const MuscleChips({super.key, required this.primaryIds, required this.secondaryIds});

  String _fallbackName(MuscleRegion region) {
    switch (region) {
      case MuscleRegion.brust:
        return 'Brust';
      case MuscleRegion.schulter:
        return 'Schulter';
      case MuscleRegion.nacken:
        return 'Nacken';
      case MuscleRegion.ruecken:
        return 'Rücken';
      case MuscleRegion.bizeps:
        return 'Bizeps';
      case MuscleRegion.trizeps:
        return 'Trizeps';
      case MuscleRegion.bauch:
        return 'Bauch';
      case MuscleRegion.quadrizeps:
        return 'Quadrizeps';
      case MuscleRegion.hamstrings:
        return 'Hamstrings';
      case MuscleRegion.waden:
        return 'Waden';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (primaryIds.isEmpty && secondaryIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final groups = context.watch<MuscleGroupProvider>().groups;
    final loc = AppLocalizations.of(context)!;

    MuscleRegion regionFor(String id, MuscleGroup? g) {
      if (g != null) return g.region;
      return MuscleRegion.values.firstWhereOrNull((r) => r.name == id) ?? MuscleRegion.bauch;
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
        label: '$name, ${primary ? loc.muscleTabsPrimary : loc.muscleTabsSecondary}',
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
