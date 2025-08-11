import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
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
  State<DeviceMuscleAssignmentSheet> createState() => _DeviceMuscleAssignmentSheetState();
}

class _DeviceMuscleAssignmentSheetState extends State<DeviceMuscleAssignmentSheet> {
  late Set<String> _primary;
  late Set<String> _secondary;

  @override
  void initState() {
    super.initState();
    _primary = widget.initialPrimary.toSet();
    _secondary = widget.initialSecondary.toSet();
  }

  void _togglePrimary(String id) {
    setState(() {
      if (_primary.contains(id)) {
        _primary.remove(id);
      } else {
        _primary.add(id);
        _secondary.remove(id);
      }
    });
  }

  void _toggleSecondary(String id) {
    setState(() {
      if (_secondary.contains(id)) {
        _secondary.remove(id);
      } else {
        _secondary.add(id);
        _primary.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = context.watch<MuscleGroupProvider>().groups;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.deviceName} – Muskelgruppen',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Primär', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final g in groups)
                  FilterChip(
                    key: ValueKey('p-${g.id}'),
                    avatar: CircleAvatar(
                      backgroundColor: colorForRegion(g.region, theme),
                      radius: 6,
                    ),
                    label: Text(g.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: _primary.contains(g.id),
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: theme.colorScheme.onPrimary,
                    labelStyle: TextStyle(
                      color: _primary.contains(g.id)
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (_) => _togglePrimary(g.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Sekundär', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final g in groups)
                  FilterChip(
                    key: ValueKey('s-${g.id}'),
                    avatar: CircleAvatar(
                      backgroundColor: colorForRegion(g.region, theme),
                      radius: 6,
                    ),
                    label: Text(g.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: _secondary.contains(g.id),
                    selectedColor: theme.colorScheme.secondary,
                    checkmarkColor: theme.colorScheme.onSecondary,
                    labelStyle: TextStyle(
                      color: _secondary.contains(g.id)
                          ? theme.colorScheme.onSecondary
                          : theme.colorScheme.onSurface,
                    ),
                    onSelected: (_) => _toggleSecondary(g.id),
                  ),
              ],
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
                    await context.read<MuscleGroupProvider>().updateDeviceAssignments(
                          context,
                          widget.deviceId,
                          _primary.toList(),
                          _secondary.toList(),
                        );
                    if (mounted) Navigator.pop(context);
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
}

