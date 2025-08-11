import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'search_and_filters.dart' show SortOrder;

class FilterChipsRow extends StatelessWidget {
  final SortOrder sort;
  final ValueChanged<SortOrder> onSort;
  final Set<String> muscleFilterIds;
  final ValueChanged<Set<String>> onMuscleFilter;
  final VoidCallback onReset;

  const FilterChipsRow({
    super.key,
    required this.sort,
    required this.onSort,
    required this.muscleFilterIds,
    required this.onMuscleFilter,
    required this.onReset,
  });

  Future<void> _showSortSheet(BuildContext context) async {
    final res = await showModalBottomSheet<SortOrder>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('A→Z'),
              onTap: () => Navigator.pop(ctx, SortOrder.az),
            ),
            ListTile(
              title: Text('Z→A'),
              onTap: () => Navigator.pop(ctx, SortOrder.za),
            ),
          ],
        ),
      ),
    );
    if (res != null) onSort(res);
  }

  Future<void> _showMuscleSheet(BuildContext context) async {
    final prov = context.read<MuscleGroupProvider>();
    final groups = prov.groups;
    final selected = Set<String>.from(muscleFilterIds);
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in groups)
                      FilterChip(
                        label: Text(g.name),
                        selected: selected.contains(g.id),
                        onSelected: (v) {
                          setSt(() {
                            if (v) {
                              selected.add(g.id);
                            } else {
                              selected.remove(g.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    onMuscleFilter(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        ChoiceChip(
          label: Text(loc.filterNameChip),
          selected: sort == SortOrder.za,
          onSelected: (_) => _showSortSheet(context),
          selectedColor: theme.colorScheme.primaryContainer,
          showCheckmark: false,
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text(loc.filterMuscleChip),
          selected: muscleFilterIds.isNotEmpty,
          onSelected: (_) => _showMuscleSheet(context),
          selectedColor: theme.colorScheme.primaryContainer,
          showCheckmark: false,
        ),
        const Spacer(),
        SizedBox(
          height: 48,
          child: TextButton(
            onPressed: onReset,
            child: Text(loc.resetFilters),
          ),
        ),
      ],
    );
  }
}

