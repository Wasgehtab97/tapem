import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/muscle_group/domain/models/muscle_group.dart';
import 'package:tapem/ui/muscles/muscle_group_color.dart';

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
  MuscleRegion? _primary;
  late Set<MuscleRegion> _secondary;
  MuscleRegion? _initialPrimary;
  late Set<MuscleRegion> _initialSecondary;
  bool _initialized = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _secondary = <MuscleRegion>{};
  }

  static const List<MuscleRegion> _order = [
    MuscleRegion.chest,
    MuscleRegion.shoulders,
    MuscleRegion.legs,
    MuscleRegion.back,
    MuscleRegion.arms,
    MuscleRegion.core,
  ];

  String _regionLabel(MuscleRegion region) {
    switch (region) {
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

  String _displayName(MuscleRegion region, MuscleGroup? g) {
    final name = g?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return _regionLabel(region);
  }

  Map<MuscleRegion, MuscleGroup?> _canonical(List<MuscleGroup> groups) {
    final map = <MuscleRegion, MuscleGroup?>{for (var r in MuscleRegion.values) r: null};
    final byRegion = <MuscleRegion, List<MuscleGroup>>{};
    for (final g in groups) {
      byRegion.putIfAbsent(g.region, () => []).add(g);
    }
    const canonicalNames = {
      MuscleRegion.chest: 'chest',
      MuscleRegion.back: 'back',
      MuscleRegion.shoulders: 'shoulders',
      MuscleRegion.arms: 'arms',
      MuscleRegion.legs: 'legs',
      MuscleRegion.core: 'core',
    };
    for (final r in MuscleRegion.values) {
      final list = byRegion[r];
      if (list == null || list.isEmpty) continue;
      MuscleGroup chosen = list.first;
      for (final g in list) {
        if (g.name.toLowerCase() == canonicalNames[r]) {
          chosen = g;
          break;
        }
      }
      map[r] = chosen;
    }
    return map;
  }

  bool _matchesQuery(MuscleRegion region, MuscleGroup? g) {
    final q = _query.toLowerCase();
    if (q.isEmpty) return true;
    final label = _regionLabel(region).toLowerCase();
    final name = (g?.name ?? '').toLowerCase();
    return label.contains(q) || name.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = context.watch<MuscleGroupProvider>().groups;
    final canon = _canonical(groups);
    if (!_initialized && groups.isNotEmpty) {
      final idToRegion = {
        for (final e in canon.entries)
          if (e.value != null) e.value!.id: e.key,
      };
      _primary = widget.initialPrimary.isEmpty
          ? null
          : idToRegion[widget.initialPrimary.first];
      _secondary = widget.initialSecondary
          .map((id) => idToRegion[id])
          .whereType<MuscleRegion>()
          .toSet();
      _secondary.remove(_primary);
      _initialPrimary = _primary;
      _initialSecondary = Set.of(_secondary);
      _initialized = true;
    }

    final entries = _order
        .map((r) => MapEntry(r, canon[r]))
        .where((e) => _matchesQuery(e.key, e.value))
        .toList();

    final canSave =
        ((_primary != null) || _secondary.isNotEmpty) &&
            (_primary != _initialPrimary ||
                !setEquals(_secondary, _initialSecondary));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${widget.deviceName} – Muskelgruppen',
                      style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: () async {
                    await context
                        .read<MuscleGroupProvider>()
                        .updateDeviceAssignments(
                          context,
                          widget.deviceId,
                          const [],
                          const [],
                        );
                    if (!mounted) return;
                    Navigator.pop(context, const {'primary': [], 'secondary': []});
                  },
                  child: const Text('Zurücksetzen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Text('Primär', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final e in entries)
                    _buildPrimaryRow(e.key, e.value, theme),
                  const SizedBox(height: 16),
                  Text('Sekundär', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final e in entries)
                    _buildSecondaryRow(e.key, e.value, theme),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canSave
                      ? () async {
                          final prov =
                              context.read<MuscleGroupProvider>();
                          final idMap = <MuscleRegion, String>{};
                          for (final region in {if (_primary != null) _primary!, ..._secondary}) {
                            final g = canon[region];
                            if (g != null) {
                              idMap[region] = g.id;
                            } else {
                              final id = await prov.ensureRegionGroup(context, region);
                              if (id != null) idMap[region] = id;
                            }
                          }
                          final primaryIds = _primary == null
                              ? <String>[]
                              : [idMap[_primary!]!];
                          final secondaryIds = _secondary
                              .map((r) => idMap[r]!)
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
                      : null,
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryRow(
      MuscleRegion region, MuscleGroup? g, ThemeData theme) {
    final name = _displayName(region, g);
    return Semantics(
      label: '$name, primär auswählen',
      child: InkWell(
        onTap: () {
          setState(() {
            _primary = region;
            _secondary.remove(region);
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
              Radio<MuscleRegion>(
                value: region,
                groupValue: _primary,
                onChanged: (r) {
                  setState(() {
                    _primary = r;
                    if (r != null) _secondary.remove(r);
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

  Widget _buildSecondaryRow(
      MuscleRegion region, MuscleGroup? g, ThemeData theme) {
    final name = _displayName(region, g);
    final checked = _secondary.contains(region);
    final disabled = _primary == region;
    return Semantics(
      label: '$name, sekundär auswählen',
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                setState(() {
                  if (checked) {
                    _secondary.remove(region);
                  } else {
                    _secondary.add(region);
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
                            _secondary.add(region);
                          } else {
                            _secondary.remove(region);
                          }
                        });
                      },
                fillColor: MaterialStateProperty.resolveWith(
                    (states) => theme.colorScheme.tertiary),
                checkColor: theme.colorScheme.onTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

