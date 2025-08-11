import 'package:flutter/material.dart';
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
  String? _primaryId;
  late Set<String> _secondary;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _primaryId =
        widget.initialPrimary.isEmpty ? null : widget.initialPrimary.first;
    _secondary = widget.initialSecondary.toSet()..remove(_primaryId);
  }

  String _displayName(MuscleGroup g) {
    if (g.name.trim().isNotEmpty) return g.name;
    switch (g.region) {
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
      default:
        return 'Core';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = context.watch<MuscleGroupProvider>().groups;
    final filtered = groups
        .where((g) =>
            _displayName(g).toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.deviceName} – Muskelgruppen',
                style: theme.textTheme.titleLarge),
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
                  for (final g in filtered) _buildPrimaryRow(g, theme),
                  const SizedBox(height: 16),
                  Text('Sekundär', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final g in filtered) _buildSecondaryRow(g, theme),
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
                  onPressed: () async {
                    final primary =
                        _primaryId == null ? const <String>[] : <String>[_primaryId!];
                    final secondary =
                        _secondary.where((id) => id != _primaryId).toList();
                    await context.read<MuscleGroupProvider>().updateDeviceAssignments(
                          context,
                          widget.deviceId,
                          primary,
                          secondary,
                        );
                    if (!mounted) return;
                    Navigator.pop(context, {
                      'primary': primary,
                      'secondary': secondary,
                    });
                  },
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryRow(MuscleGroup g, ThemeData theme) {
    final name = _displayName(g);
    return Semantics(
      label: '$name, Primary selector',
      child: InkWell(
        onTap: () {
          setState(() {
            _primaryId = g.id;
            _secondary.remove(g.id);
          });
        },
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: colorForRegion(g.region, theme)),
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
                value: g.id,
                groupValue: _primaryId,
                onChanged: (id) {
                  setState(() {
                    _primaryId = id;
                    if (id != null) _secondary.remove(id);
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

  Widget _buildSecondaryRow(MuscleGroup g, ThemeData theme) {
    final name = _displayName(g);
    final checked = _secondary.contains(g.id);
    final disabled = _primaryId == g.id;
    return Semantics(
      label: '$name, Secondary selector',
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                setState(() {
                  if (checked) {
                    _secondary.remove(g.id);
                  } else {
                    _secondary.add(g.id);
                  }
                });
              },
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              CircleAvatar(backgroundColor: colorForRegion(g.region, theme)),
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
                            _secondary.add(g.id);
                          } else {
                            _secondary.remove(g.id);
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

