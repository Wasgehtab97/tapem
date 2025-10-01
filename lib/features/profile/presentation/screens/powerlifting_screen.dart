// lib/features/profile/presentation/screens/powerlifting_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/models/exercise.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_discipline.dart';
import 'package:tapem/features/profile/domain/models/powerlifting_record.dart';
import 'package:tapem/features/profile/presentation/providers/powerlifting_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class PowerliftingScreen extends StatefulWidget {
  const PowerliftingScreen({super.key});

  @override
  State<PowerliftingScreen> createState() => _PowerliftingScreenState();
}

class _PowerliftingScreenState extends State<PowerliftingScreen> {
  Future<void> _onAddPressed() async {
    final provider = context.read<PowerliftingProvider>();
    final loc = AppLocalizations.of(context)!;
    final gymId = provider.activeGymId;

    if (gymId == null || gymId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.powerliftingNoGymError)),
      );
      return;
    }

    final discipline = await _selectDiscipline(loc);
    if (!mounted || discipline == null) return;

    final devices = await provider.loadDevicesForActiveGym();
    if (!mounted) return;

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.powerliftingNoDevicesError)),
      );
      return;
    }

    final device = await _selectDevice(loc, devices, discipline);
    if (!mounted || device == null) return;

    String exerciseId = device.uid;
    if (device.isMulti) {
      final exercises = await provider.loadExercisesForDevice(device.uid);
      if (!mounted) return;

      if (exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.powerliftingNoExercisesError(device.name))),
        );
        return;
      }

      final exercise = await _selectExercise(loc, device, exercises);
      if (!mounted || exercise == null) return;
      exerciseId = exercise.id;
    }

    final success = await provider.addAssignment(
      discipline: discipline,
      gymId: gymId,
      deviceId: device.uid,
      exerciseId: exerciseId,
    );

    if (!mounted) return;

    if (!success) {
      final message = provider.error == 'POWERLIFTING_DUPLICATE'
          ? loc.powerliftingDuplicateError
          : provider.error ?? loc.powerliftingAddError;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.powerliftingAddSuccess)),
      );
    }
  }

  Future<PowerliftingDiscipline?> _selectDiscipline(AppLocalizations loc) {
    final theme = Theme.of(context);
    return showModalBottomSheet<PowerliftingDiscipline>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  loc.powerliftingDisciplineSheetTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              for (final discipline in PowerliftingDiscipline.values)
                ListTile(
                  title: Text(_disciplineLabel(loc, discipline)),
                  onTap: () => Navigator.of(sheetContext).pop(discipline),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<Device?> _selectDevice(
    AppLocalizations loc,
    List<Device> devices,
    PowerliftingDiscipline discipline,
  ) {
    final theme = Theme.of(context);
    return showModalBottomSheet<Device>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    loc.powerliftingDeviceSheetTitle(
                      _disciplineLabel(loc, discipline),
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (_, index) {
                      final device = devices[index];
                      final subtitle = device.isMulti
                          ? loc.powerliftingDeviceIsMultiNote
                          : null;
                      return ListTile(
                        title: Text(device.name),
                        subtitle:
                            subtitle == null ? null : Text(subtitle),
                        onTap: () => Navigator.of(sheetContext).pop(device),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Exercise?> _selectExercise(
    AppLocalizations loc,
    Device device,
    List<Exercise> exercises,
  ) {
    final theme = Theme.of(context);
    return showModalBottomSheet<Exercise>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    loc.powerliftingExerciseSheetTitle(device.name),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (_, index) {
                      final exercise = exercises[index];
                      return ListTile(
                        title: Text(exercise.name),
                        onTap: () => Navigator.of(sheetContext).pop(exercise),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<PowerliftingProvider>();
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);

    Widget body;
    if (provider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (!provider.hasAssignments) {
      body = _EmptyState(
        title: loc.powerliftingEmptyTitle,
        description: loc.powerliftingEmptyDescription,
        buttonLabel: loc.powerliftingAddButton,
        onAdd: provider.isSaving ? null : _onAddPressed,
      );
    } else {
      final columns = PowerliftingDiscipline.values
          .map(
            (discipline) => _DisciplineColumn(
              label: _disciplineLabel(loc, discipline),
              records: provider.recordsFor(discipline),
              dateFormat: dateFormat,
              emptyLabel: loc.powerliftingNoRecords,
            ),
          )
          .toList();

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.powerliftingIntro,
            style: theme.textTheme.bodyMedium?.copyWith(color: brandColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _PowerliftingTable(columns: columns),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.powerliftingTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.powerliftingAddTooltip,
            onPressed: provider.isSaving ? null : _onAddPressed,
          ),
        ],
      ),
      body: SafeArea(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: body,
          ),
        ),
      ),
    );
  }

  String _disciplineLabel(
    AppLocalizations loc,
    PowerliftingDiscipline discipline,
  ) {
    switch (discipline) {
      case PowerliftingDiscipline.benchPress:
        return loc.powerliftingBenchPress;
      case PowerliftingDiscipline.squat:
        return loc.powerliftingSquat;
      case PowerliftingDiscipline.deadlift:
        return loc.powerliftingDeadlift;
    }
  }
}

class _PowerliftingTable extends StatelessWidget {
  const _PowerliftingTable({required this.columns});

  final List<_DisciplineColumn> columns;

  @override
  Widget build(BuildContext context) {
    final maxRows = columns
        .map((column) => column.records.length)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);
    final headerStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.bold);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      border: TableBorder.symmetric(
        inside: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      children: [
        TableRow(
          children: [
            for (final column in columns)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                child: Text(
                  column.label,
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),
          ],
        ),
        if (maxRows == 0)
          TableRow(
            children: [
              for (final column in columns)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    column.emptyLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          )
        else
          for (var row = 0; row < maxRows; row++)
            TableRow(
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    child: column.buildCell(row),
                  ),
              ],
            ),
      ],
    );
  }
}

class _DisciplineColumn {
  _DisciplineColumn({
    required this.label,
    required this.records,
    required this.dateFormat,
    required this.emptyLabel,
  });

  final String label;
  final List<PowerliftingRecord> records;
  final DateFormat dateFormat;
  final String emptyLabel;

  Widget buildCell(int index) {
    if (index >= records.length) {
      return const Text('-', textAlign: TextAlign.center);
    }

    final record = records[index];
    final dateText = dateFormat.format(record.performedAt);
    final subtitle = record.exerciseName ?? record.deviceName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('${record.weightKg.toStringAsFixed(1)} kg × ${record.reps}'),
        const SizedBox(height: 4),
        Text(
          dateText,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onAdd,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 320,
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
