import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/history/providers/history_provider.dart';
import 'package:tapem/core/utils/nice_scale.dart';
import 'package:tapem/features/history/domain/models/workout_log.dart';
import 'package:tapem/features/training_details/domain/models/session.dart';
import 'package:tapem/features/training_details/presentation/widgets/session_exercise_card.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/logging/elog.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;
  final String? deviceDescription;
  final bool isMulti;
  final String? exerciseId;
  final String? exerciseName;
  final String? ownerUserId;
  const HistoryScreen({
    Key? key,
    required this.deviceId,
    required this.deviceName,
    this.deviceDescription,
    this.isMulti = false,
    this.exerciseId,
    this.exerciseName,
    this.ownerUserId,
  }) : super(key: key);

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final Map<String, GlobalKey<_HistoryExpansionTileState>>
      _expansionKeysBySessionId = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authViewStateProvider);
      final gymId = auth.gymCode;
      final userId = widget.ownerUserId ?? auth.userId;
      if (gymId == null || userId == null) {
        return;
      }
      unawaited(
        ref.read(historyProvider).loadHistory(
              gymId: gymId,
              deviceId: widget.deviceId,
              userId: userId,
              exerciseId: widget.isMulti ? widget.exerciseId : null,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final auth = ref.watch(authViewStateProvider);
    final historyUserId = widget.ownerUserId ?? auth.userId ?? '';
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;
    final prov = ref.watch(historyProvider);
    final smallStyle = textTheme.bodySmall?.copyWith(
      color: brandColor.withOpacity(0.7),
      fontSize: 10,
    );

    if (prov.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final title = widget.isMulti ? (widget.exerciseName ?? '') : widget.deviceName;
    final subtitle = widget.deviceDescription ?? '';
    final fullTitle =
        subtitle.isNotEmpty ? '$title — $subtitle' : title;
    if (prov.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: BrandGradientText(
            fullTitle,
            style: textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          foregroundColor: brandColor,
        ),
        body: DefaultTextStyle.merge(
          style: TextStyle(color: brandColor),
          child: Center(
            child: Text('${loc.errorPrefix}: ${prov.error}'),
          ),
        ),
      );
    }

    final e1rmPoints = prov.e1rmChart;
    final localeString = Localizations.localeOf(context).toString();

    final e1rmValues = e1rmPoints.map((e) => e.value).toList();
    final e1rmScale = NiceScale.fromValues(e1rmValues,
        tickCount: 6, clampMinZero: true);
    final e1rmSpots = e1rmValues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final e1rmDateInterval =
        e1rmPoints.isEmpty ? 1 : (e1rmPoints.length / 6).ceil().clamp(1, e1rmPoints.length);

    final sessionsMap = <String, List<WorkoutLog>>{};
    for (var log in prov.logs) {
      sessionsMap.putIfAbsent(log.sessionId, () => []).add(log);
    }
    final sessionEntries = sessionsMap.entries.toList()
      ..sort((a, b) {
        return b.value.first.timestamp.compareTo(a.value.first.timestamp);
      });
    final bestSetValue = _formatBestSet(prov.bestSet);
    final dateKeyToSessionId = <String, String>{};
    final trainingDates = <String>{};
    for (final entry in sessionEntries) {
      final dateKey = _formatDateKey(entry.value.first.timestamp);
      trainingDates.add(dateKey);
      dateKeyToSessionId.putIfAbsent(dateKey, () => entry.key);
    }
    final initialCalendarYear = sessionEntries.isNotEmpty
        ? sessionEntries.first.value.first.timestamp.year
        : DateTime.now().year;
    final kpis = [
      _KpiTileData(
        label: loc.historyWorkouts,
        value: prov.workoutCount.toString(),
        description: loc.historyWorkoutsDesc,
        icon: Icons.calendar_month_rounded,
        onTap: () => _showHistoryCalendar(
          trainingDates: trainingDates.toList(),
          initialYear: initialCalendarYear,
          dateKeyToSessionId: dateKeyToSessionId,
          userId: historyUserId,
        ),
      ),
      _KpiTileData(
        label: loc.historySetsAvg,
        value: prov.setsPerSessionAvg.toStringAsFixed(1),
        description: loc.historySetsAvgDesc,
        icon: Icons.repeat_rounded,
      ),
      _KpiTileData(
        label: loc.historyHeaviest,
        value: bestSetValue,
        description: loc.historyHeaviestDesc,
        icon: Icons.fitness_center_rounded,
      ),
      _KpiTileData(
        label: loc.historyAxisE1rm,
        value: '${prov.maxE1rm.toStringAsFixed(1)} kg',
        description: loc.historyE1rmDesc,
        icon: Icons.trending_up_rounded,
      ),
    ];

    Widget buildE1rmChart() {
      if (e1rmPoints.isEmpty) {
        return SizedBox(
            height: 200,
            child: Center(child: Text(loc.historyNoData, style: textTheme.bodySmall)));
      }
      final dates = e1rmPoints.map((e) => e.date).toList();
      return Semantics(
        label: loc.historyE1rmChartSemantics,
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: e1rmScale.min,
              maxY: e1rmScale.max,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: e1rmScale.tickSpacing,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(loc.historyAxisDate, style: smallStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: e1rmDateInterval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= dates.length) {
                        return const SizedBox();
                      }
                      final d = dates[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat.Md(localeString).format(d),
                          style: smallStyle,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(loc.historyAxisE1rm, style: smallStyle),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: e1rmScale.tickSpacing,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: smallStyle,
                    ),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: e1rmSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: LineTouchData(enabled: false),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: BrandGradientText(
          fullTitle,
          style: textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        foregroundColor: brandColor,
      ),
      body: DefaultTextStyle.merge(
        style: TextStyle(color: brandColor),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      loc.historyOverviewTitle,
                      style:
                          textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 72,
                      child: Row(
                        children: [
                          Expanded(child: _kpiTile(kpis[0], compact: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _kpiTile(kpis[1], compact: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _kpiTile(kpis[2], compact: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _kpiTile(kpis[3], compact: true)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.historyChartTitle,
                      style:
                          textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    buildE1rmChart(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  loc.historyListTitle,
                  style:
                      textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                sessionEntries.map((entry) {
                  final logs = entry.value;
                  final titleDate =
                      DateFormat.yMMMMd(localeString).format(logs.first.timestamp);
                  final expansionKey = _expansionKeysBySessionId.putIfAbsent(
                    entry.key,
                    () => GlobalKey<_HistoryExpansionTileState>(),
                  );

                  final sets = logs
                      .map((e) => SessionSet(
                            weight: e.weight,
                            reps: e.reps,
                            setNumber: e.setNumber,
                            dropWeightKg: e.dropWeightKg,
                            dropReps: e.dropReps,
                            isBodyweight: e.isBodyweight,
                          ))
                      .toList();
                  elogUi('HISTORY_CARD_RENDER', {
                    'sessionId': entry.key,
                    'setNumbers': sets.take(10).map((s) => s.setNumber).toList(),
                  });
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _HistoryExpansionTile(
                      key: expansionKey,
                      title: titleDate,
                      child: SessionExerciseCard(
                        title: title,
                        subtitle: subtitle.isNotEmpty ? subtitle : null,
                        sets: sets,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  String _formatBestSet(WorkoutLog? log) {
    if (log == null) return '-';
    final formatter = NumberFormat('0.##');
    final weightStr = log.isBodyweight
        ? (log.weight == 0 ? 'BW' : 'BW+${formatter.format(log.weight)}')
        : formatter.format(log.weight);
    return '$weightStr×${log.reps}';
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _showHistoryCalendar({
    required List<String> trainingDates,
    required int initialYear,
    required Map<String, String> dateKeyToSessionId,
    required String userId,
  }) async {
    final selected = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CalendarPopup(
        trainingDates: trainingDates,
        initialYear: initialYear,
        userId: userId,
        navigateOnTap: false,
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    final dateKey = _formatDateKey(selected);
    final sessionId = dateKeyToSessionId[dateKey];
    if (sessionId == null) {
      return;
    }
    final expansionKey = _expansionKeysBySessionId[sessionId];
    final targetContext = expansionKey?.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.12,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    expansionKey?.currentState?.setExpanded(true);
  }

  void _showKpiInfo({required String title, required String description}) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BrandGradientText(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kpiTile(_KpiTileData data, {bool compact = false}) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    final background = theme.colorScheme.surface.withOpacity(0.65);
    final onTap = data.onTap ??
        () => _showKpiInfo(
              title: data.label,
              description: data.description,
            );
    return BrandInteractiveCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      showShadow: false,
      enableScaleAnimation: false,
      backgroundColor: background,
      restingBorderColor: onSurface.withOpacity(0.08),
      activeBorderColor: accent.withOpacity(0.45),
      semanticLabel: '${data.label}: ${data.value}. ${data.description}',
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: BrandGradientText(
                    data.value,
                    style: (compact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withOpacity(0.65),
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  size: 14,
                  color: accent.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: accent.withOpacity(0.55),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiTileData {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  const _KpiTileData({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    this.onTap,
  });
}

class _HistoryExpansionTile extends StatefulWidget {
  final String title;
  final Widget child;
  const _HistoryExpansionTile({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  State<_HistoryExpansionTile> createState() => _HistoryExpansionTileState();
}

class _HistoryExpansionTileState extends State<_HistoryExpansionTile> {
  bool _expanded = false;

  void setExpanded(bool expanded) {
    if (_expanded == expanded) {
      return;
    }
    setState(() => _expanded = expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.secondary;
    final borderRadius = BorderRadius.circular(22);
    final onSurface = theme.colorScheme.onSurface;
    final background = theme.colorScheme.surface.withOpacity(0.65);

    return BrandInteractiveCard(
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      enableScaleAnimation: false,
      backgroundColor: background,
      restingBorderColor: onSurface.withOpacity(0.08),
      activeBorderColor: accent.withOpacity(0.45),
      semanticLabel: widget.title,
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.1),
                      border: Border.all(
                        color: accent.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: accent,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: widget.child,
              ),
          ],
        ),
      ),
    );
  }
}
