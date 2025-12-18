import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/ui/muscles/muscle_group_display.dart';

class MuscleChips extends StatelessWidget {
  final List<String> primaryIds;
  final List<String> secondaryIds;
  const MuscleChips({super.key, required this.primaryIds, required this.secondaryIds});

  @override
  Widget build(BuildContext context) {
    if (primaryIds.isEmpty && secondaryIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final groups = riverpod.ProviderScope.containerOf(context)
        .read(muscleGroupProvider)
        .groups;
    final loc = AppLocalizations.of(context)!;

    MuscleRegion regionFor(String id, MuscleGroup? g) {
      if (g != null) return g.region;
      return MuscleRegion.values.firstWhereOrNull((r) => r.name == id) ?? MuscleRegion.bauch;
    }

    String nameFor(String id) {
      final g = groups.firstWhereOrNull((e) => e.id == id);
      final region = regionFor(id, g);
      return displayNameForMuscleGroup(region, g);
    }

    final onSurface = theme.colorScheme.onSurface;
    final highlight = theme.colorScheme.primary;

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: onSurface.withOpacity(0.75),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    );

    Widget buildChip(String id, bool primary) {
      final name = nameFor(id);
      final backgroundColor = primary
          ? highlight.withOpacity(0.12)
          : onSurface.withOpacity(0.06);
      final borderColor = primary
          ? highlight.withOpacity(0.2)
          : onSurface.withOpacity(0.12);
      return Semantics(
        label: '$name, ${primary ? loc.muscleTabsPrimary : loc.muscleTabsSecondary}',
        child: Chip(
          visualDensity: VisualDensity.compact,
          backgroundColor: backgroundColor,
          shape: StadiumBorder(side: BorderSide(color: borderColor)),
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          label: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
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
