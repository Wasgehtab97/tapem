import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';

import 'muscle_group_color.dart';

class MuscleGroupListSelector extends StatefulWidget {
  final List<String> initialPrimary;
  final List<String> initialSecondary;
  final void Function(List<String> primary, List<String> secondary) onChanged;
  final String filter;

  const MuscleGroupListSelector({
    super.key,
    required this.initialPrimary,
    required this.initialSecondary,
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

  /// Display categories for grouping muscle regions.
  static const List<_Category> _categories = [
    _Category.chest,
    _Category.shoulders,
    _Category.arms,
    _Category.back,
    _Category.core,
    _Category.legs,
  ];

  _Category _categoryFor(MuscleRegion r) {
    switch (r) {
      case MuscleRegion.chest:
        return _Category.chest;
      case MuscleRegion.anteriorDeltoid:
      case MuscleRegion.posteriorDeltoid:
      case MuscleRegion.upperTrapezius:
        return _Category.shoulders;
      case MuscleRegion.biceps:
      case MuscleRegion.triceps:
      case MuscleRegion.wristFlexors:
        return _Category.arms;
      case MuscleRegion.lats:
      case MuscleRegion.midBack:
        return _Category.back;
      case MuscleRegion.rectusAbdominis:
      case MuscleRegion.obliques:
      case MuscleRegion.transversusAbdominis:
        return _Category.core;
      case MuscleRegion.quadriceps:
      case MuscleRegion.hamstrings:
      case MuscleRegion.glutes:
      case MuscleRegion.adductors:
      case MuscleRegion.abductors:
      case MuscleRegion.calves:
      case MuscleRegion.tibialisAnterior:
        return _Category.legs;
    }
  }

  String _categoryLabel(_Category c, AppLocalizations loc) {
    switch (c) {
      case _Category.chest:
        return loc.muscleCategoryChest;
      case _Category.shoulders:
        return loc.muscleCategoryShoulders;
      case _Category.arms:
        return loc.muscleCategoryArms;
      case _Category.back:
        return loc.muscleCategoryBack;
      case _Category.core:
        return loc.muscleCategoryCore;
      case _Category.legs:
        return loc.muscleCategoryLegs;
    }
  }

  late List<String> _selected;
  String? _primaryId;
  late List<String> _initialPrimary;
  late List<String> _initialSecondary;

  @override
  void initState() {
    super.initState();
    _selected = [...widget.initialPrimary, ...widget.initialSecondary];
    _primaryId = widget.initialPrimary.isNotEmpty ? widget.initialPrimary.first : null;
    _initialPrimary = List.of(widget.initialPrimary);
    _initialSecondary = List.of(widget.initialSecondary);
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
        _primaryId == null ? [] : [_primaryId!],
        _selected.where((x) => x != _primaryId).toList(),
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

  void _clear() {
    setState(() {
      _selected.clear();
      _primaryId = null;
    });
    _emit();
  }

  void _reset() {
    setState(() {
      _selected = [..._initialPrimary, ..._initialSecondary];
      _primaryId = _initialPrimary.isNotEmpty ? _initialPrimary.first : null;
    });
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

    final Map<_Category, List<_Entry>> byCat = {
      for (final c in _categories) c: [],
    };
    for (final r in _ordered) {
      final g = canonical[r];
      final name =
          g != null && g.name.isNotEmpty ? g.name : _regionFallbackName(r);
      if (name.toLowerCase().contains(widget.filter.toLowerCase())) {
        final key = g?.id ?? r.name;
        byCat[_categoryFor(r)]!
            .add(_Entry(region: r, group: g, displayName: name, key: key));
      }
    }

    final hasEntries = byCat.values.any((e) => e.isNotEmpty);
    if (!hasEntries) {
      return Center(child: Text(loc.exerciseNoMuscleGroups));
    }

    final green = theme.colorScheme.primary;
    final blue = theme.colorScheme.tertiary;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _clear,
                child: Text(loc.exerciseEdit_clearAll),
              ),
              TextButton(
                onPressed: _reset,
                child: Text(loc.exerciseEdit_reset),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (final c in _categories)
                if (byCat[c]!.isNotEmpty) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      _categoryLabel(c, loc),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in byCat[c]!)
                        SizedBox(
                          height: 48,
                          child: Semantics(
                            selected: entry.group?.id != null &&
                                _selected.contains(entry.group!.id),
                            button: true,
                            label: entry.displayName,
                            child: GestureDetector(
                              onLongPress: () async {
                                final id = await _ensureIdForRegion(
                                    entry.region, entry.key);
                                _setPrimary(id);
                              },
                              child: FilterChip(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                avatar: CircleAvatar(
                                  backgroundColor:
                                      colorForRegion(entry.region, theme),
                                  radius: 8,
                                ),
                                label: Text(entry.displayName,
                                    softWrap: true, maxLines: 2),
                                selected: entry.group?.id != null &&
                                    _selected.contains(entry.group!.id),
                                onSelected: (_) =>
                                    _toggleSelect(entry.key, entry.region),
                                selectedColor: entry.group?.id != null &&
                                        _primaryId == entry.group!.id
                                    ? green
                                    : blue,
                                showCheckmark: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
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

enum _Category { chest, shoulders, arms, back, core, legs }

