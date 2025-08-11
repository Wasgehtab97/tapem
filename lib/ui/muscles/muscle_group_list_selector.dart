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
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.initialSelection);
  }

  String _regionFallbackName(MuscleRegion r) {
    switch (r) {
      case MuscleRegion.chest:
        return 'Chest';
      case MuscleRegion.back:
        return 'Back';
      case MuscleRegion.shoulders:
        return 'Shoulders';
      case MuscleRegion.arms:
        return 'Arms';
      case MuscleRegion.legs:
        return 'Legs';
      case MuscleRegion.core:
        return 'Core';
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onChanged(_selected);
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
        .where((g) {
          final name = g.name.isNotEmpty ? g.name : _regionFallbackName(g.region);
          return name.toLowerCase().contains(widget.filter.toLowerCase());
        })
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
        final displayName = g.name.isNotEmpty ? g.name : _regionFallbackName(g.region);
        final textStyle = theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface);
        return InkWell(
          onTap: () => _toggle(g.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorForRegion(g.region, theme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
                Checkbox(
                  value: selected,
                  onChanged: (_) => _toggle(g.id),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => Divider(
        color: theme.colorScheme.outlineVariant,
        height: 1,
      ),
      itemCount: groups.length,
    );
  }
}

