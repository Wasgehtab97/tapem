import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'muscle_group_color.dart';

class MuscleGroupListSelector extends StatefulWidget {
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;
  final String filter;

  const MuscleGroupListSelector({
    super.key,
    required this.initialSelection,
    required this.onChanged,
    this.filter = '',
  });

  @override
  State<MuscleGroupListSelector> createState() => _MuscleGroupListSelectorState();
}

class _MuscleGroupListSelectorState extends State<MuscleGroupListSelector> {
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
        .where((g) => g.name.toLowerCase().contains(widget.filter.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (groups.isEmpty) {
      return Center(child: Text(loc.exerciseNoMuscleGroups));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final g = groups[index];
        final selected = _selected.contains(g.id);
        return ListTile(
          onTap: () => _toggle(g.id),
          leading: CircleAvatar(
            backgroundColor: colorForRegion(g.region, theme),
          ),
          title: Text(
            g.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Checkbox(
            value: selected,
            onChanged: (_) => _toggle(g.id),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: groups.length,
    );
  }
}

