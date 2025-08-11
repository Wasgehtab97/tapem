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
  State<MuscleGroupListSelector> createState() =>
      _MuscleGroupListSelectorState();
}

class _MuscleGroupListSelectorState extends State<MuscleGroupListSelector> {
  static const List<MuscleRegion> _ordered = [
    MuscleRegion.chest,
    MuscleRegion.anteriorDeltoid,
    MuscleRegion.biceps,
    MuscleRegion.wristFlexors,
    MuscleRegion.lats,
    MuscleRegion.midBack,
    MuscleRegion.posteriorDeltoid,
    MuscleRegion.upperTrapezius,
    MuscleRegion.triceps,
    MuscleRegion.rectusAbdominis,
    MuscleRegion.obliques,
    MuscleRegion.transversusAbdominis,
    MuscleRegion.quadriceps,
    MuscleRegion.hamstrings,
    MuscleRegion.glutes,
    MuscleRegion.adductors,
    MuscleRegion.abductors,
    MuscleRegion.calves,
    MuscleRegion.tibialisAnterior,
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

  Future<String> _ensureIdForRegion(
    MuscleRegion region,
    String idOrRegionKey,
  ) async {
    final prov = context.read<MuscleGroupProvider>();
    if (prov.groups.any((g) => g.id == idOrRegionKey)) {
      return idOrRegionKey;
    }
    final g = await prov.getOrCreateByRegion(
      context,
      region,
      defaultName: _regionFallbackName(region),
    );
    return g.id;
  }

  void _emit() => widget.onChanged(
        _primaryId == null
            ? []
            : [_primaryId!, ..._selected.where((x) => x != _primaryId)],
      );

  void _toggleSelect(String idOrRegionKey, MuscleRegion region) async {
    final id = await _ensureIdForRegion(region, idOrRegionKey);
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
    if (!_selected.contains(id)) _selected.add(id);
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
      } else if (current.name.isEmpty && g.name.isNotEmpty) {
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
      final name =
          g != null && g.name.isNotEmpty ? g.name : _regionFallbackName(r);
      if (name.toLowerCase().contains(widget.filter.toLowerCase())) {
        final key = g?.id ?? r.name;
        entries.add(
          _Entry(region: r, group: g, displayName: name, key: key),
        );
      }
    }

    if (entries.isEmpty) {
      return Center(child: Text(loc.exerciseNoMuscleGroups));
    }

    final green = theme.colorScheme.primary;
    final blue = theme.colorScheme.tertiary;

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final id = entry.group?.id;
        final isSel = id != null && _selected.contains(id);
        final isPri = id != null && _primaryId == id;
        final textStyle = theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        );

        return InkWell(
          onTap: () => _toggleSelect(entry.key, entry.region),
          onLongPress: () async {
            final id = await _ensureIdForRegion(entry.region, entry.key);
            _setPrimary(id);
          },
          child: Padding(
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
                Checkbox(
                  value: isSel,
                  onChanged: (_) => _toggleSelect(entry.key, entry.region),
                  fillColor: MaterialStateProperty.resolveWith(
                    (states) => isSel ? (isPri ? green : blue) : null,
                  ),
                  checkColor: theme.colorScheme.onPrimary,
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
      itemCount: entries.length,
    );
  }
}

class _Entry {
  final MuscleRegion region;
  final MuscleGroup? group;
  final String displayName;
  final String key;

  _Entry({
    required this.region,
    required this.group,
    required this.displayName,
    required this.key,
  });
}

