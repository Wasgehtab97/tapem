import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'muscle_group_color.dart';

class MuscleGroupSelector extends StatefulWidget {
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;
  final String filter;

  const MuscleGroupSelector({
    super.key,
    required this.initialSelection,
    required this.onChanged,
    this.filter = '',
  });

  @override
  State<MuscleGroupSelector> createState() => _MuscleGroupSelectorState();
}

class _MuscleGroupSelectorState extends State<MuscleGroupSelector> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      widget.onChanged(_selected.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prov = context.watch<MuscleGroupProvider>();
    final theme = Theme.of(context);

    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groups = prov.groups
        .where(
            (g) => g.name.toLowerCase().contains(widget.filter.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (groups.isEmpty) {
      return Center(child: Text(loc.exerciseNoMuscleGroups));
    }

    final Map<MuscleCategory, List<MuscleGroup>> grouped = {};
    for (final g in groups) {
      grouped.putIfAbsent(g.region.category, () => []).add(g);
    }

    String catLabel(MuscleCategory c) {
      switch (c) {
        case MuscleCategory.upperFront:
          return loc.muscleCatUpperFront;
        case MuscleCategory.upperBack:
          return loc.muscleCatUpperBack;
        case MuscleCategory.core:
          return loc.muscleCatCore;
        case MuscleCategory.lower:
          return loc.muscleCatLower;
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final cat in MuscleCategory.values)
            if (grouped[cat] != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Text(catLabel(cat), style: theme.textTheme.titleMedium),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final g in grouped[cat]!)
                    Semantics(
                      label: _selected.contains(g.id)
                          ? loc.a11yMgSelected(g.name)
                          : loc.a11yMgUnselected(g.name),
                      child: FilterChip(
                        key: ValueKey(g.id),
                        avatar: CircleAvatar(
                          backgroundColor: colorForRegion(g.region),
                          radius: 6,
                        ),
                        label: Text(
                          g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: _selected.contains(g.id),
                        selectedColor: theme.colorScheme.primary,
                        checkmarkColor: theme.colorScheme.onPrimary,
                        labelStyle: TextStyle(
                          color: _selected.contains(g.id)
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        onSelected: (_) => _toggle(g.id),
                      ),
                    ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}
