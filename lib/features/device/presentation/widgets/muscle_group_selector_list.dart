import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

class MuscleGroupSelectorList extends StatefulWidget {
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;
  final String filter;

  const MuscleGroupSelectorList({
    super.key,
    required this.initialSelection,
    required this.onChanged,
    this.filter = '',
  });

  @override
  State<MuscleGroupSelectorList> createState() => _MuscleGroupSelectorListState();
}

class _MuscleGroupSelectorListState extends State<MuscleGroupSelectorList> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet();
  }

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
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceVariant,
            radius: 8,
          ),
          title: Container(
            height: 16,
            color: theme.colorScheme.surfaceVariant,
          ),
        ),
      );
    }

    final groups = prov.groups
        .where((g) =>
            g.name.toLowerCase().contains(widget.filter.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (groups.isEmpty) {
      return Center(child: Text(loc.exerciseNoMuscleGroups));
    }

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final g = groups[index];
        final selected = _selected.contains(g.id);
        return Semantics(
          label: selected
              ? loc.a11yMgSelected(g.name)
              : loc.a11yMgUnselected(g.name),
          child: ListTile(
            key: ValueKey(g.id),
            leading: CircleAvatar(
              backgroundColor: _colorForRegion(g.region, theme),
              radius: 8,
            ),
            title: Text(
              g.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Checkbox(
              value: selected,
              onChanged: (_) => _toggle(g.id),
            ),
            onTap: () => _toggle(g.id),
          ),
        );
      },
    );
  }
}

