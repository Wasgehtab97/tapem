import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/nice_scale.dart';
import 'package:tapem/core/widgets/brand_gradient_text.dart';
import 'package:tapem/core/widgets/brand_interactive_card.dart';
import 'package:tapem/features/progress/providers/progress_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({Key? key, this.onExitToProfile}) : super(key: key);

  final VoidCallback? onExitToProfile;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedYear = DateTime.now().year;

  void _handleBackPressed() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onExitToProfile?.call();
  }

  Widget? _buildLeadingBackButton() {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && widget.onExitToProfile == null) {
      return null;
    }
    return IconButton(
      onPressed: _handleBackPressed,
      icon: const Icon(Icons.chevron_left_rounded),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadYear(_selectedYear);
    });
  }

  void _loadYear(int year) {
    final auth = ref.read(authViewStateProvider);
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) return;
    ref
        .read(progressProvider)
        .loadYear(gymId: gymId, userId: userId, year: year);
  }

  Future<void> _loadMore() async {
    final auth = ref.read(authViewStateProvider);
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) return;
    await ref.read(progressProvider).loadMore(gymId: gymId, userId: userId);
  }

  Future<void> _runBackfill() async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.progressBackfillTitle),
          content: Text(loc.progressBackfillBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.progressBackfillCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.progressBackfillConfirm),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final auth = ref.read(authViewStateProvider);
    final gymId = auth.gymCode;
    final userId = auth.userId;
    if (gymId == null || userId == null) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    final result = await ref
        .read(progressProvider)
        .backfillYear(gymId: gymId, userId: userId, year: _selectedYear);

    if (!context.mounted) return;
    Navigator.pop(context);
    if (result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.progressBackfillDone(result.sessionCount, result.exerciseCount),
        ),
      ),
    );
  }

  List<int> _yearOptions() {
    const startYear = 2025;
    final current = DateTime.now().year;
    final endYear = current < startYear ? startYear : current;
    return List.generate(endYear - startYear + 1, (i) => endYear - i);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;
    final prov = ref.watch(progressProvider);

    final years = _yearOptions();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _buildLeadingBackButton(),
        title: BrandGradientText(
          loc.progressTitle,
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        foregroundColor: brandColor,
        actions: [
          IconButton(
            tooltip: loc.progressInfoAction,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(loc.progressInfoTitle),
                    content: Text(loc.progressInfoBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          MaterialLocalizations.of(context).okButtonLabel,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            tooltip: loc.progressBackfillAction,
            onPressed: prov.isBackfilling ? null : _runBackfill,
            icon: prov.isBackfilling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: DefaultTextStyle.merge(
        style: TextStyle(color: brandColor),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _YearSelectorCard(
                  label: loc.progressYearLabel,
                  value: _selectedYear,
                  years: years,
                  onChanged: (year) {
                    if (year == null || year == _selectedYear) return;
                    setState(() => _selectedYear = year);
                    _loadYear(year);
                  },
                ),
              ),
            ),
            if (prov.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${loc.errorPrefix}: ${prov.error}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (prov.isLoading && prov.visibleItems.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (prov.visibleItems.isEmpty) {
                    return _EmptyState(
                      title: loc.progressEmptyTitle,
                      subtitle: loc.progressEmptySubtitle,
                      actionLabel: loc.progressBackfillConfirm,
                      onAction: prov.isBackfilling ? null : _runBackfill,
                    );
                  }

                  final localeString = Localizations.localeOf(
                    context,
                  ).toString();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount:
                        prov.visibleItems.length + (prov.canLoadMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= prov.visibleItems.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: prov.isLoadingMore
                                ? const CircularProgressIndicator()
                                : OutlinedButton(
                                    onPressed: _loadMore,
                                    child: Text(loc.progressLoadMore),
                                  ),
                          ),
                        );
                      }

                      final item = prov.visibleItems[index];
                      final points = prov.pointsFor(item.key);
                      final meta = prov.metaFor(item.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProgressChartCard(
                          item: item,
                          points: points,
                          meta: meta,
                          localeString: localeString,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _YearSelectorCard extends StatelessWidget {
  const _YearSelectorCard({
    required this.label,
    required this.value,
    required this.years,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> years;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.10), accent.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onSurface.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: accent.withOpacity(0.85),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isDense: true,
              dropdownColor: theme.colorScheme.surface,
              style: theme.textTheme.titleSmall?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w700,
              ),
              icon: Icon(
                Icons.expand_more_rounded,
                color: accent.withOpacity(0.9),
              ),
              items: years
                  .map(
                    (year) => DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChartCard extends StatelessWidget {
  const _ProgressChartCard({
    required this.item,
    required this.points,
    required this.meta,
    required this.localeString,
  });

  final ProgressIndexItem item;
  final List<ProgressPoint> points;
  final ProgressMetaView? meta;
  final String localeString;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final accent = brand?.outline ?? theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    final background = theme.colorScheme.surface.withOpacity(0.65);
    final loc = AppLocalizations.of(context)!;

    final smallStyle = theme.textTheme.bodySmall?.copyWith(
      color: accent.withOpacity(0.7),
      fontSize: 10,
    );

    final e1rmValues = points.map((e) => e.value).toList();
    final e1rmScale = NiceScale.fromValues(
      e1rmValues,
      tickCount: 6,
      clampMinZero: true,
    );
    final e1rmSpots = e1rmValues
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final dates = points.map((e) => e.date).toList();
    final dateInterval = points.isEmpty
        ? 1
        : (points.length / 6).ceil().clamp(1, points.length);

    final resolvedIsMulti = meta?.isMulti ?? item.isMulti;
    final resolvedTitle = (meta?.title.isNotEmpty ?? false)
        ? meta!.title
        : item.title;
    final resolvedSubtitle = (meta?.subtitle.isNotEmpty ?? false)
        ? meta!.subtitle
        : item.subtitle;
    final showSubtitle = resolvedIsMulti && resolvedSubtitle.isNotEmpty;
    final looksLikeId = _looksLikeId(resolvedTitle);
    final displayTitle =
        (resolvedIsMulti && looksLikeId && resolvedSubtitle.isNotEmpty)
        ? resolvedSubtitle
        : resolvedTitle;
    final displaySubtitle = (resolvedIsMulti && looksLikeId)
        ? ''
        : resolvedSubtitle;

    return BrandInteractiveCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppRadius.cardLg),
      showShadow: false,
      enableScaleAnimation: false,
      backgroundColor: background,
      restingBorderColor: onSurface.withOpacity(0.08),
      activeBorderColor: accent.withOpacity(0.45),
      semanticLabel: item.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showSubtitle && displaySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displaySubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withOpacity(0.25), width: 1),
                ),
                child: Text(
                  '${item.sessionCount} ${loc.historyWorkouts}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (points.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  loc.historyNoData,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            SizedBox(
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
                      axisNameWidget: Text(
                        loc.historyAxisDate,
                        style: smallStyle,
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: dateInterval.toDouble(),
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
                      axisNameWidget: Text(
                        loc.historyAxisE1rm,
                        style: smallStyle,
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: e1rmScale.tickSpacing,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toStringAsFixed(0), style: smallStyle),
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
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
        ],
      ),
    );
  }

  bool _looksLikeId(String value) {
    if (value.length < 16) return false;
    final normalized = value.replaceAll('-', '');
    final isHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized);
    return isHex;
  }
}
