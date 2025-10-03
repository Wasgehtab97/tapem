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
  PowerliftingMetric _selectedMetric = PowerliftingMetric.heaviest;

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

    final selections = await _selectAssignments(
      loc,
      discipline,
      devices,
    );

    if (!mounted || selections == null || selections.isEmpty) {
      return;
    }

    var successCount = 0;
    var duplicateFailure = false;
    String? failureMessage;

    for (final selection in selections) {
      final success = await provider.addAssignment(
        discipline: discipline,
        gymId: gymId,
        deviceId: selection.deviceId,
        exerciseId: selection.exerciseId,
      );

      final error = provider.error;

      if (success) {
        successCount++;
      } else if (error == 'POWERLIFTING_DUPLICATE') {
        duplicateFailure = true;
      } else {
        failureMessage =
            (error == null || error.isEmpty) ? loc.powerliftingAddError : error;
      }
    }

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final totalSelections = selections.length;
    final successMessage = loc.powerliftingAddSuccess;
    final duplicateMessage = loc.powerliftingDuplicateError;

    if (successCount == totalSelections &&
        !duplicateFailure &&
        failureMessage == null) {
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      return;
    }

    final messages = <String>[];
    if (successCount > 0) {
      messages.add(successMessage);
    }
    if (duplicateFailure) {
      messages.add(duplicateMessage);
    }
    if (failureMessage != null) {
      messages.add(failureMessage!);
    }

    if (messages.isEmpty) {
      messages.add(loc.powerliftingAddError);
    }

    messenger.showSnackBar(
      SnackBar(content: Text(messages.join(' – '))),
    );
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

  Future<List<_AssignmentSelection>?> _selectAssignments(
    AppLocalizations loc,
    PowerliftingDiscipline discipline,
    List<Device> devices,
  ) async {
    final provider = context.read<PowerliftingProvider>();
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final exerciseMap = <String, List<Exercise>>{};
    final unavailableDevices = <Device>[];

    for (final device in devices.where((d) => d.isMulti)) {
      final exercises = await provider.loadExercisesForDevice(device.uid);
      if (!mounted) {
        return null;
      }

      if (exercises.isEmpty) {
        unavailableDevices.add(device);
        continue;
      }

      exerciseMap[device.uid] = exercises;
    }

    if (unavailableDevices.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loc.powerliftingNoExercisesError(unavailableDevices.first.name),
          ),
        ),
      );
    }

    final availableDevices = devices
        .where((device) => !device.isMulti || exerciseMap.containsKey(device.uid))
        .toList();

    if (availableDevices.isEmpty) {
      return null;
    }

    return showModalBottomSheet<List<_AssignmentSelection>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final selected = <_AssignmentSelection>{};
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.75,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(
                          loc.powerliftingAssignmentSheetTitle(
                            _disciplineLabel(loc, discipline),
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          children: [
                            for (final device in availableDevices)
                              if (!device.isMulti)
                                Builder(
                                  builder: (_) {
                                    final selection = _AssignmentSelection(
                                      deviceId: device.uid,
                                      exerciseId: device.uid,
                                      deviceName: device.name,
                                    );
                                    return CheckboxListTile(
                                      value: selected.contains(selection),
                                      title: Text(device.name),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked ?? false) {
                                            selected.add(selection);
                                          } else {
                                            selected.remove(selection);
                                          }
                                        });
                                      },
                                    );
                                  },
                                )
                              else
                                ExpansionTile(
                                  title: Text(device.name),
                                  subtitle: Text(loc.powerliftingDeviceIsMultiNote),
                                  childrenPadding: const EdgeInsets.only(
                                    left: AppSpacing.md,
                                    right: AppSpacing.md,
                                  ),
                                  children: [
                                    for (final exercise in exerciseMap[device.uid]!)
                                      Builder(
                                        builder: (_) {
                                          final selection = _AssignmentSelection(
                                            deviceId: device.uid,
                                            exerciseId: exercise.id,
                                            deviceName: device.name,
                                            exerciseName: exercise.name,
                                          );
                                          return CheckboxListTile(
                                            value: selected.contains(selection),
                                            title: Text(exercise.name),
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                            ),
                                            onChanged: (checked) {
                                              setState(() {
                                                if (checked ?? false) {
                                                  selected.add(selection);
                                                } else {
                                                  selected.remove(selection);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                  ],
                                ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: Text(loc.commonCancel),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () => Navigator.of(sheetContext)
                                      .pop(selected.toList()),
                              child: Text(loc.commonSave),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
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
              records: provider.recordsFor(
                discipline,
                metric: _selectedMetric,
              ),
              dateFormat: dateFormat,
              emptyLabel: loc.powerliftingNoRecords,
              metric: _selectedMetric,
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
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final introText = Text(
                            loc.powerliftingIntro,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.9),
                              height: 1.4,
                            ),
                          );
                          final switcher = _PowerliftingTableSwitcher(
                            selectedMetric: _selectedMetric,
                            onMetricChanged: (metric) {
                              setState(() {
                                _selectedMetric = metric;
                              });
                            },
                          );

                          if (constraints.maxWidth < 520) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                introText,
                                const SizedBox(height: AppSpacing.md),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: switcher,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: introText),
                              const SizedBox(width: AppSpacing.md),
                              switcher,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GradientFrame(
                        child: _PowerliftingTable(columns: columns),
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: body,
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

class _PowerliftingTableSwitcher extends StatelessWidget {
  const _PowerliftingTableSwitcher({
    required this.selectedMetric,
    required this.onMetricChanged,
  });

  final PowerliftingMetric selectedMetric;
  final ValueChanged<PowerliftingMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;

    Color resolveForeground(Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return colorScheme.onPrimary;
      }
      return colorScheme.onSurface;
    }

    return SegmentedButton<PowerliftingMetric>(
      segments: [
        ButtonSegment<PowerliftingMetric>(
          value: PowerliftingMetric.heaviest,
          label: Text(loc.powerliftingHeaviestTable),
          icon: const Icon(Icons.monitor_weight_outlined),
        ),
        ButtonSegment<PowerliftingMetric>(
          value: PowerliftingMetric.e1rm,
          label: Text(loc.powerliftingE1rmTable),
          icon: const Icon(Icons.trending_up_outlined),
        ),
      ],
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith(resolveForeground),
        iconColor: MaterialStateProperty.resolveWith(resolveForeground),
      ),
      selected: <PowerliftingMetric>{selectedMetric},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onMetricChanged(selection.first);
      },
    );
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
    final theme = Theme.of(context);
    const tableBackground = Colors.black;
    const headerBackground = Color(0xFF121212);
    const alternateRowBackground = Color(0xFF181818);
    final dividerColor = Colors.white.withOpacity(0.14);

    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withOpacity(0.7),
      height: 1.3,
    );

    final tableBorder = TableBorder(
      top: const BorderSide(color: Colors.transparent, width: 0),
      bottom: const BorderSide(color: Colors.transparent, width: 0),
      left: const BorderSide(color: Colors.transparent, width: 0),
      right: const BorderSide(color: Colors.transparent, width: 0),
      horizontalInside: BorderSide(color: dividerColor, width: 1),
      verticalInside: BorderSide(color: dividerColor, width: 1),
    );

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: tableBorder,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: headerBackground),
          children: [
            for (final column in columns)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    column.label,
                    textAlign: TextAlign.center,
                    style: headerStyle,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
        if (maxRows == 0)
            TableRow(
              decoration: const BoxDecoration(color: tableBackground),
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
                color: row.isEven ? tableBackground : alternateRowBackground,
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

class _AssignmentSelection {
  const _AssignmentSelection({
    required this.deviceId,
    required this.exerciseId,
    required this.deviceName,
    this.exerciseName,
  });

  final String deviceId;
  final String exerciseId;
  final String deviceName;
  final String? exerciseName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _AssignmentSelection &&
        other.deviceId == deviceId &&
        other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => Object.hash(deviceId, exerciseId);
}

class _DisciplineColumn {
  _DisciplineColumn({
    required this.label,
    required this.records,
    required this.dateFormat,
    required this.emptyLabel,
    required this.metric,
  });

  final String label;
  final List<PowerliftingRecord> records;
  final DateFormat dateFormat;
  final String emptyLabel;
  final PowerliftingMetric metric;

  Widget buildCell(int index, TextStyle? valueStyle, TextStyle? metaStyle) {
    if (index >= records.length) {
      return Text('-', textAlign: TextAlign.center, style: valueStyle);
    }

    final record = records[index];
    final dateText = dateFormat.format(record.performedAt);
    final subtitle = record.exerciseName ?? record.deviceName;
    final mainValue = switch (metric) {
      PowerliftingMetric.heaviest =>
          '${_formatWeight(record.weightKg)} kg × ${record.reps}',
      PowerliftingMetric.e1rm =>
          '${_formatWeight(record.e1rm)} kg E1RM',
    };
    final supportingValue =
        metric == PowerliftingMetric.e1rm
            ? '${_formatWeight(record.weightKg)} kg × ${record.reps}'
            : null;

    final children = <Widget>[
      Text(
        mainValue,
        style: valueStyle,
        textAlign: TextAlign.center,
      ),
    ];

    if (supportingValue != null) {
      children.addAll([
        const SizedBox(height: 4),
        Text(
          supportingValue,
          style: metaStyle,
          textAlign: TextAlign.center,
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 6),
      Text(
        dateText,
        style: metaStyle,
        textAlign: TextAlign.center,
      ),
    ]);

    if (subtitle.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: metaStyle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  String _formatWeight(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
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
    const background = Colors.black;

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
