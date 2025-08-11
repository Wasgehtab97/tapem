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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // POLISH: smoother scroll in bottom sheet
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final g in groups)
            Semantics(
              label: _selected.contains(g.id)
                  ? loc.a11yMgSelected(g.name)
                  : loc.a11yMgUnselected(g.name),
              child: FilterChip(
                key: ValueKey(g.id),
                avatar: CircleAvatar(
                  backgroundColor: colorForRegion(g.region, theme),
                  radius: 6,
                ),
                label: Text(
                  g.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: _selected.contains(g.id),
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: theme.colorScheme.onPrimary,
                onSelected: (_) => _toggle(g.id),
              ),
            ),
        ],
      ),
    );
  }
}
