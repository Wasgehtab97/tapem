import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/muscles/muscle_group_color.dart';

/// Bottom sheet for assigning primary and secondary muscle groups to a device.
class DeviceMuscleAssignmentSheet extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final List<String> initialPrimary;
  final List<String> initialSecondary;

  const DeviceMuscleAssignmentSheet({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.initialPrimary,
    required this.initialSecondary,
  });

  @override
  State<DeviceMuscleAssignmentSheet> createState() =>
      _DeviceMuscleAssignmentSheetState();
}

class _DeviceMuscleAssignmentSheetState
    extends State<DeviceMuscleAssignmentSheet> {
  final TextEditingController _searchCtr = TextEditingController();

  String? _selectedPrimaryId;
  late Set<String> _selectedSecondaryIds;

  String? _initialPrimaryId;
  late Set<String> _initialSecondaryIds;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedSecondaryIds = <String>{};
    _initialSecondaryIds = <String>{};
    _searchCtr.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    super.dispose();
  }

  static const List<MuscleRegion> _order = [
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

  String _regionLabel(AppLocalizations loc, MuscleRegion region) {
    // Using English fallback if not localized
    switch (region) {
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

  Map<MuscleRegion, MuscleGroup?> _canonical(List<MuscleGroup> groups) {
    final map = <MuscleRegion, MuscleGroup?>{for (var r in MuscleRegion.values) r: null};
    final byRegion = <MuscleRegion, List<MuscleGroup>>{};
    for (final g in groups) {
      byRegion.putIfAbsent(g.region, () => []).add(g);
    }
    for (final r in MuscleRegion.values) {
      final list = byRegion[r];
      if (list == null || list.isEmpty) continue;
      MuscleGroup chosen = list.first;
      for (final g in list) {
        if (g.name.toLowerCase() == r.name.toLowerCase()) {
          chosen = g;
          break;
        }
      }
      map[r] = chosen;
    }
    return map;
  }

  bool _matchesQuery(AppLocalizations loc, MuscleRegion region, MuscleGroup? g) {
    final q = _searchCtr.text.toLowerCase();
    if (q.isEmpty) return true;
    final label = _regionLabel(loc, region).toLowerCase();
    final name = (g?.name ?? '').toLowerCase();
    return label.contains(q) || name.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final groups = context.watch<MuscleGroupProvider>().groups;
    final canon = _canonical(groups);

    if (!_initialized && groups.isNotEmpty) {
      _selectedPrimaryId = widget.initialPrimary.isEmpty ? null : widget.initialPrimary.first;
      _selectedSecondaryIds = widget.initialSecondary.toSet();
      _selectedSecondaryIds.remove(_selectedPrimaryId);
      _initialPrimaryId = _selectedPrimaryId;
      _initialSecondaryIds = Set.of(_selectedSecondaryIds);
      _initialized = true;
    }

    final entries = _order
        .map((r) => MapEntry(r, canon[r]))
        .where((e) => _matchesQuery(loc, e.key, e.value))
        .toList();

    final idToData = {
      for (final e in canon.entries)
        (e.value?.id ?? e.key.name): (region: e.key, group: e.value)
    };

    Future<void> save() async {
      final prov = context.read<MuscleGroupProvider>();
      final Set<String> all = {
        if (_selectedPrimaryId != null) _selectedPrimaryId!,
        ..._selectedSecondaryIds,
      };
      final Map<String, String> resolved = {};
      for (final id in all) {
        final data = idToData[id];
        if (data == null) continue;
        if (data.group != null) {
          resolved[id] = data.group!.id;
        } else {
          final newId =
              await prov.ensureRegionGroup(context, data.region);
          if (newId != null) {
            resolved[id] = newId;
          }
        }
      }
      final primaryIds =
          _selectedPrimaryId == null ? <String>[] : [resolved[_selectedPrimaryId!]!];
      final secondaryIds = _selectedSecondaryIds
          .map((e) => resolved[e]!)
          .where((id) => !primaryIds.contains(id))
          .toList();
      await prov.updateDeviceAssignments(
        context,
        widget.deviceId,
        primaryIds,
        secondaryIds,
      );
      if (!mounted) return;
      Navigator.pop(context, {
        'primary': primaryIds,
        'secondary': secondaryIds,
      });
    }

    Future<void> reset() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(loc.resetMuscleGroupsConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.reset),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await context.read<MuscleGroupProvider>().updateDeviceAssignments(
              context,
              widget.deviceId,
              const [],
              const [],
            );
        if (!mounted) return;
        Navigator.pop(context, const {'primary': [], 'secondary': []});
      }
    }

    final canSave = _selectedPrimaryId != null &&
        (_selectedPrimaryId != _initialPrimaryId ||
            !setEquals(_selectedSecondaryIds, _initialSecondaryIds));

    final primaryBadge = _selectedPrimaryId == null ? 0 : 1;
    final secondaryBadge = _selectedSecondaryIds.length;

    Widget buildPrimaryList() {
      if (entries.isEmpty) {
        return _EmptyTab(
          message: loc.emptyPrimary,
          onReset: () => _searchCtr.clear(),
        );
      }
      return ListView(
        key: const PageStorageKey('primaryList'),
        children: [
          for (final e in entries)
            _buildPrimaryRow(loc, theme, e.key, e.value),
          if (_selectedPrimaryId == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                loc.mustSelectPrimary,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      );
    }

    Widget buildSecondaryList() {
      if (entries.isEmpty) {
        return _EmptyTab(
          message: loc.emptySecondary,
          onReset: () => _searchCtr.clear(),
        );
      }
      return ListView(
        key: const PageStorageKey('secondaryList'),
        children: [
          for (final e in entries)
            _buildSecondaryRow(loc, theme, e.key, e.value),
        ],
      );
    }

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.deviceName} — ${loc.muscleGroupTitle}',
                      style: theme.textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: reset,
                    child: Text(loc.reset),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtr,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.exerciseSearchMuscleGroupsHint,
                  suffixIcon: _searchCtr.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => _searchCtr.clear(),
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                tabs: [
                  Tab(text: '${loc.muscleTabsPrimary} ($primaryBadge)'),
                  Tab(text: '${loc.muscleTabsSecondary} ($secondaryBadge)'),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    buildPrimaryList(),
                    buildSecondaryList(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: canSave ? save : null,
                    child: Text(loc.commonSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryRow(AppLocalizations loc, ThemeData theme,
      MuscleRegion region, MuscleGroup? g) {
    final id = g?.id ?? region.name;
    final name = (g?.name.trim().isNotEmpty ?? false)
        ? g!.name
        : _regionLabel(loc, region);
    final selected = _selectedPrimaryId == id;
    return Semantics(
      label: '$name, ${loc.muscleTabsPrimary}',
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPrimaryId = id;
            _selectedSecondaryIds.remove(id);
          });
        },
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: colorForRegion(region, theme)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
              Radio<String>(
                value: id,
                groupValue: _selectedPrimaryId,
                onChanged: (v) {
                  setState(() {
                    _selectedPrimaryId = v;
                    if (v != null) _selectedSecondaryIds.remove(v);
                  });
                },
                fillColor: MaterialStateProperty.resolveWith(
                    (states) => theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryRow(AppLocalizations loc, ThemeData theme,
      MuscleRegion region, MuscleGroup? g) {
    final id = g?.id ?? region.name;
    final name = (g?.name.trim().isNotEmpty ?? false)
        ? g!.name
        : _regionLabel(loc, region);
    final checked = _selectedSecondaryIds.contains(id);
    final disabled = _selectedPrimaryId == id;
    return Semantics(
      label: '$name, ${loc.muscleTabsSecondary}',
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                setState(() {
                  if (checked) {
                    _selectedSecondaryIds.remove(id);
                  } else {
                    _selectedSecondaryIds.add(id);
                  }
                });
              },
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: colorForRegion(region, theme)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
              Checkbox(
                value: checked,
                onChanged: disabled
                    ? null
                    : (v) {
                        setState(() {
                          if (v == true) {
                            _selectedSecondaryIds.add(id);
                          } else {
                            _selectedSecondaryIds.remove(id);
                          }
                        });
                      },
                fillColor: MaterialStateProperty.resolveWith(
                    (states) => theme.colorScheme.tertiary),
                checkColor: theme.colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String message;
  final VoidCallback onReset;

  const _EmptyTab({required this.message, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 8),
          TextButton(onPressed: onReset, child: Text(loc.resetFilters)),
        ],
      ),
    );
  }
}

