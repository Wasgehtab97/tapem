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

  Future<void> _onClearPressed() async {
    final provider = context.read<PowerliftingProvider>();
    final loc = AppLocalizations.of(context)!;

    final shouldReset = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(loc.powerliftingClearConfirmTitle),
            content: Text(loc.powerliftingClearConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(loc.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(loc.powerliftingClearConfirmAction),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !shouldReset) {
      return;
    }

    final success = await provider.clearAssignments();
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.powerliftingClearSuccess)),
      );
    } else {
      final message = provider.error ?? loc.powerliftingClearError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _GradientFrame(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _EmptyState(
              title: loc.powerliftingEmptyTitle,
              description: loc.powerliftingEmptyDescription,
              buttonLabel: loc.powerliftingAddButton,
              onAdd: provider.isSaving ? null : _onAddPressed,
              accentColor: brandColor,
            ),
          ),
        ),
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

      body = LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.powerliftingIntro,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GradientFrame(
                        child: _PowerliftingTable(
                          columns: columns,
                          accentColor: brandColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.powerliftingTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: loc.powerliftingClearTooltip,
            onPressed: provider.isSaving || !provider.hasAssignments
                ? null
                : _onClearPressed,
          ),
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
  const _PowerliftingTable({required this.columns, required this.accentColor});

  final List<_DisciplineColumn> columns;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final maxRows = columns
        .map((column) => column.records.length)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
      height: 1.3,
    );
    final dividerColor = theme.colorScheme.outline.withOpacity(0.25);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
          ),
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
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: dividerColor, width: 1),
              ),
            ),
            children: [
              for (final column in columns)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    column.emptyLabel,
                    textAlign: TextAlign.center,
                    style: metaStyle,
                  ),
                ),
            ],
          )
        else
          for (var row = 0; row < maxRows; row++)
            TableRow(
              decoration: BoxDecoration(
                color: row.isEven
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.1)
                    : Colors.transparent,
                border: Border(
                  top: BorderSide(color: dividerColor, width: 1),
                ),
              ),
              children: [
                for (final column in columns)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: column.buildCell(row, valueStyle, metaStyle),
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

  Widget buildCell(int index, TextStyle? valueStyle, TextStyle? metaStyle) {
    if (index >= records.length) {
      return Text('-', textAlign: TextAlign.center, style: valueStyle);
    }

    final record = records[index];
    final dateText = dateFormat.format(record.performedAt);
    final subtitle = record.exerciseName ?? record.deviceName;
    final weight = record.weightKg % 1 == 0
        ? record.weightKg.toStringAsFixed(0)
        : record.weightKg.toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$weight kg × ${record.reps}', style: valueStyle, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          dateText,
          style: metaStyle,
          textAlign: TextAlign.center,
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: metaStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    required this.accentColor,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onAdd;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.auto_graph_rounded, size: 40, color: accentColor),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurface.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}

class _GradientFrame extends StatelessWidget {
  const _GradientFrame({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final gradient = brand?.gradient ?? AppGradients.brandGradient;
    final resolvedRadius = (brand?.outlineRadius ?? BorderRadius.circular(AppRadius.card))
        .resolve(Directionality.of(context));
    final background = theme.colorScheme.surface.withOpacity(0.85);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: resolvedRadius,
        boxShadow: brand?.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: resolvedRadius,
          child: Container(
            color: background,
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
