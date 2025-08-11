import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'muscle_group_color.dart';

class MuscleGroupListSelector extends StatefulWidget {
  final String? deviceId;
  final List<String> initialSelection;
  final ValueChanged<List<String>> onChanged;
  final String filter;

  const MuscleGroupListSelector({
    super.key,
    this.deviceId,
    required this.initialSelection,
    required this.onChanged,
    this.filter = '',
  });

  @override
  State<MuscleGroupListSelector> createState() => _MuscleGroupListSelectorState();
}

class _MuscleGroupListSelectorState extends State<MuscleGroupListSelector> {
  static const List<MuscleRegion> _ordered = [
    MuscleRegion.chest,
    MuscleRegion.back,
    MuscleRegion.shoulders,
    MuscleRegion.arms,
    MuscleRegion.legs,
    MuscleRegion.core,
  ];

  late List<String> _selected;
  String? _primaryId;

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.initialSelection);
    _primaryId = _selected.isNotEmpty ? _selected.first : null;
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

  void _emit() => widget.onChanged(
        _primaryId == null
            ? []
            : [
                _primaryId!,
                ..._selected.where((id) => id != _primaryId),
              ],
      );

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_primaryId == id) {
          _primaryId = _selected.isNotEmpty ? _selected.first : null;
        }
      } else {
        _selected.add(id);
        _primaryId ??= id;
      }
    });
    _emit();
  }

  void _setPrimary(String id) {
    if (!_selected.contains(id)) {
      _selected.add(id);
    }
    setState(() => _primaryId = id);
    _emit();
  }

  Map<MuscleRegion, MuscleGroup?> _buildCanonical(List<MuscleGroup> all) {
    final Map<MuscleRegion, MuscleGroup?> canonical = {
      for (final r in _ordered) r: null
    };

    for (final g in all) {
      final current = canonical[g.region];
      if (current == null) {
        canonical[g.region] = g;
        continue;
      }

      final preferByDevice = widget.deviceId != null &&
          (g.primaryDeviceIds.contains(widget.deviceId) ||
              g.secondaryDeviceIds.contains(widget.deviceId));
      final currentByDevice = widget.deviceId != null &&
          (current.primaryDeviceIds.contains(widget.deviceId) ||
              current.secondaryDeviceIds.contains(widget.deviceId));
      final preferByName = g.name.isNotEmpty && current.name.isEmpty;

      if ((preferByDevice && !currentByDevice) || preferByName) {
        canonical[g.region] = g;
      }
    }

    return canonical;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prov = context.watch<MuscleGroupProvider>();
    final theme = Theme.of(context);

    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final canonical = _buildCanonical(prov.groups);

    final entries = <_Entry>[];
    for (final r in _ordered) {
      final g = canonical[r];
      var name = g != null && g.name.isNotEmpty ? g.name : _regionFallbackName(r);
      if (g == null) {
        name = '$name - not configured';
      }
      if (name.toLowerCase().contains(widget.filter.toLowerCase())) {
        entries.add(_Entry(region: r, group: g, displayName: name));
      }
    }

    if (entries.isEmpty) {
      return Center(child: Text(loc.exerciseNoMuscleGroups));
    }

    final Color primaryFill = Colors.green;
    final Color secondaryFill = Colors.blueAccent;

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final g = entry.group;
        final disabled = g == null;
        final isSelected = g != null && _selected.contains(g.id);
        final isPrimary = g != null && _primaryId == g.id;
        final textStyle = theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        );

        Widget trailing;
        if (disabled) {
          trailing = const Icon(Icons.block);
        } else {
          trailing = Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleSelect(g.id),
            fillColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
                  ? (isPrimary ? primaryFill : secondaryFill)
                  : null,
            ),
            checkColor: Colors.white,
          );
        }

        final row = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorForRegion(entry.region, theme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              trailing,
            ],
          ),
        );

        return InkWell(
          onTap: disabled ? null : () => _toggleSelect(g!.id),
          onLongPress: disabled ? null : () => _setPrimary(g!.id),
          child: disabled ? Opacity(opacity: 0.5, child: row) : row,
        );
      },
      separatorBuilder: (_, __) => Divider(
        color: theme.colorScheme.outlineVariant,
        height: 1,
      ),
      itemCount: entries.length,
    );
  }
}

class _Entry {
  final MuscleRegion region;
  final MuscleGroup? group;
  final String displayName;

  _Entry({required this.region, required this.group, required this.displayName});
}

