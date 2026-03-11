import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/utils/chart_interval.dart';
import 'package:tapem/core/widgets/premium_action_tile.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_bucket.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_weight_range.dart';
import 'package:tapem/features/nutrition/presentation/widgets/nutrition_ui.dart';
import 'package:tapem/features/nutrition/providers/nutrition_weight_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class NutritionWeightScreen extends ConsumerStatefulWidget {
  const NutritionWeightScreen({super.key});

  @override
  ConsumerState<NutritionWeightScreen> createState() =>
      _NutritionWeightScreenState();
}

class _NutritionWeightScreenState extends ConsumerState<NutritionWeightScreen> {
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  String? _hydratedDateKey;
  String? _loadedUid;

  @override
  void initState() {
    super.initState();
    _weightFocusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeightData());
  }

  @override
  void dispose() {
    _weightFocusNode.removeListener(_handleFocusChange);
    _weightController.dispose();
    _weightFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadWeightData() async {
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;
    await _loadWeightDataForUid(uid);
  }

  Future<void> _loadWeightDataForUid(String uid) async {
    if (uid.isEmpty) return;
    await ref.read(nutritionWeightProvider).load(uid);
    if (!mounted) return;
    _loadedUid = uid;
    final state = ref.read(nutritionWeightProvider);
    _hydrateInputFromState(
      dateKey: state.selectedDateKey,
      kg: state.selectedKg,
      force: true,
    );
  }

  Future<void> _saveWeight() async {
    final loc = AppLocalizations.of(context)!;
    final uid = ref.read(authControllerProvider).userId;
    if (uid == null || uid.isEmpty) return;

    final parsed = _parseWeightInput(_weightController.text);
    if (parsed == null) {
      _showSnack(loc.nutritionWeightInvalidInput);
      return;
    }

    try {
      await ref.read(nutritionWeightProvider).saveSelectedWeight(uid, parsed);
      if (!mounted) return;
      _weightFocusNode.unfocus();
      final state = ref.read(nutritionWeightProvider);
      _hydrateInputFromState(
        dateKey: state.selectedDateKey,
        kg: state.selectedKg,
        force: true,
      );
      _showSnack(loc.nutritionWeightSaved(_formatWeight(parsed)));
    } catch (_) {
      if (!mounted) return;
      _showSnack(loc.nutritionWeightSaveError);
    }
  }

  Future<void> _shiftSelectedDate(int dayOffset) async {
    final uid = ref.read(authControllerProvider).userId;
    await ref
        .read(nutritionWeightProvider)
        .shiftSelectedDate(dayOffset, uid: uid);
    if (!mounted) return;
    final state = ref.read(nutritionWeightProvider);
    _hydrateInputFromState(
      dateKey: state.selectedDateKey,
      kg: state.selectedKg,
    );
  }

  void _hydrateInputFromState({
    required String dateKey,
    required double? kg,
    bool force = false,
  }) {
    if (!force && _weightFocusNode.hasFocus) {
      return;
    }
    final nextText = kg == null ? '' : _formatInputWeight(kg);
    if (!force &&
        _hydratedDateKey == dateKey &&
        _weightController.text == nextText) {
      return;
    }
    _weightController.text = nextText;
    _weightController.selection = TextSelection.fromPosition(
      TextPosition(offset: _weightController.text.length),
    );
    _hydratedDateKey = dateKey;
  }

  double? _parseWeightInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    if (normalized.isEmpty) return null;
    final firstDot = normalized.indexOf('.');
    var cleaned = normalized;
    if (firstDot >= 0) {
      cleaned =
          normalized.substring(0, firstDot + 1) +
          normalized.substring(firstDot + 1).replaceAll('.', '');
    }
    final parsed = double.tryParse(cleaned);
    if (parsed == null || !parsed.isFinite || parsed < 20 || parsed > 400) {
      return null;
    }
    return double.parse(parsed.toStringAsFixed(2));
  }

  String _formatInputWeight(double value) {
    final txt = value.toStringAsFixed(2);
    if (txt.endsWith('00')) {
      return txt.substring(0, txt.length - 3).replaceAll('.', ',');
    }
    if (txt.endsWith('0')) {
      return txt.substring(0, txt.length - 1).replaceAll('.', ',');
    }
    return txt.replaceAll('.', ',');
  }

  String _formatWeight(double value) => value.toStringAsFixed(2);

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(nutritionWeightProvider);
    final loc = AppLocalizations.of(context)!;

    if (!_weightFocusNode.hasFocus &&
        _hydratedDateKey != state.selectedDateKey) {
      _hydrateInputFromState(
        dateKey: state.selectedDateKey,
        kg: state.selectedKg,
      );
    }

    final uid = auth.userId;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat(
      'EEE, dd.MM.yyyy',
      localeTag,
    ).format(state.selectedDate);
    final currentLabel = state.selectedKg == null
        ? '-- kg'
        : '${_formatWeight(state.selectedKg!)} kg';
    final saveEnabled = uid != null && uid.isNotEmpty && !state.isSaving;

    if ((uid == null || uid.isEmpty) && _loadedUid != null) {
      _loadedUid = null;
    } else if (uid != null &&
        uid.isNotEmpty &&
        _loadedUid != uid &&
        !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadWeightDataForUid(uid);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.nutritionWeightTitle), centerTitle: true),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.lg,
          ),
          children: [
            NutritionCard(
              enableGlow: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 120) return;
                  if (velocity < 0) {
                    _shiftSelectedDate(1);
                  } else {
                    _shiftSelectedDate(-1);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DaySwitchButton(
                          icon: Icons.chevron_left_rounded,
                          onTap: () => _shiftSelectedDate(-1),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            dateLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          currentLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: brandColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        _DaySwitchButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () => _shiftSelectedDate(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Semantics(
                      label: loc.nutritionWeightInputSemantics,
                      textField: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.surface.withOpacity(0.55),
                          border: Border.all(
                            color: _weightFocusNode.hasFocus
                                ? brandColor.withOpacity(0.45)
                                : theme.colorScheme.outline.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                focusNode: _weightFocusNode,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,\.]'),
                                  ),
                                ],
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintText: loc.nutritionWeightInputHint,
                                  hintStyle: theme.textTheme.titleLarge
                                      ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.35),
                                      ),
                                ),
                                onSubmitted: (_) => _saveWeight(),
                              ),
                            ),
                            Text(
                              'kg',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: brandColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PremiumActionTile(
                      leading: state.isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: brandColor,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      title: loc.nutritionWeightSaveCta,
                      onTap: saveEnabled ? _saveWeight : null,
                      accentColor: brandColor,
                      showArrow: false,
                      margin: EdgeInsets.zero,
                      trailing: Icon(
                        Icons.save_rounded,
                        size: 18,
                        color: saveEnabled
                            ? brandColor
                            : theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _WeightRangeSelector(
              selectedRange: state.selectedRange,
              onSelected: (range) async {
                await ref.read(nutritionWeightProvider).setRange(range);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _WeightTrendCard(
              isLoading: state.isLoading,
              buckets: state.chartBuckets,
              brandColor: brandColor,
              chartSemanticsLabel: loc.nutritionWeightChartSemantics,
            ),
            if (uid == null || uid.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.nutritionWeightAuthRequired,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error.withOpacity(0.9),
                ),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                loc.nutritionWeightLoadError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DaySwitchButton extends StatelessWidget {
  const _DaySwitchButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface.withOpacity(0.5),
          border: Border.all(color: brandColor.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 18, color: brandColor),
      ),
    );
  }
}

class _WeightRangeSelector extends StatelessWidget {
  const _WeightRangeSelector({
    required this.selectedRange,
    required this.onSelected,
  });

  final NutritionWeightRange selectedRange;
  final ValueChanged<NutritionWeightRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final brandColor = brand?.outline ?? theme.colorScheme.secondary;
    final loc = AppLocalizations.of(context)!;

    final ranges = <NutritionWeightRange, String>{
      NutritionWeightRange.week: loc.nutritionWeightRangeWeek,
      NutritionWeightRange.month: loc.nutritionWeightRangeMonth,
      NutritionWeightRange.quarter: loc.nutritionWeightRangeQuarter,
      NutritionWeightRange.year: loc.nutritionWeightRangeYear,
    };

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: ranges.entries.map((entry) {
        final selected = entry.key == selectedRange;
        return ChoiceChip(
          selected: selected,
          label: Text(entry.value),
          onSelected: (_) => onSelected(entry.key),
          selectedColor: brandColor.withOpacity(0.22),
          backgroundColor: theme.colorScheme.surface.withOpacity(0.6),
          side: BorderSide(
            color: selected
                ? brandColor.withOpacity(0.45)
                : theme.colorScheme.outline.withOpacity(0.2),
          ),
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected
                ? brandColor
                : theme.colorScheme.onSurface.withOpacity(0.78),
          ),
        );
      }).toList(),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.isLoading,
    required this.buckets,
    required this.brandColor,
    required this.chartSemanticsLabel,
  });

  final bool isLoading;
  final List<NutritionWeightBucket> buckets;
  final Color brandColor;
  final String chartSemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>();
    final gradient = brand?.gradient ?? AppGradients.brandGradient;
    final loc = AppLocalizations.of(context)!;

    return NutritionCard(
      enableGlow: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.nutritionWeightTrendTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: brandColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.nutritionWeightTrendSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: chartSemanticsLabel,
            child: Container(
              height: 280,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.cardLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradient.colors.first.withOpacity(0.12),
                    theme.colorScheme.surface.withOpacity(0.55),
                  ],
                ),
                border: Border.all(color: brandColor.withOpacity(0.18)),
              ),
              child: buckets.isEmpty
                  ? Center(
                      child: Text(
                        loc.nutritionWeightEmptyState,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    )
                  : _WeightLineChart(
                      buckets: buckets,
                      gradient: gradient,
                      brandColor: brandColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({
    required this.buckets,
    required this.gradient,
    required this.brandColor,
  });

  final List<NutritionWeightBucket> buckets;
  final LinearGradient gradient;
  final Color brandColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = buckets.map((e) => e.avgKg).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = (maxValue - minValue).abs();
    final pad = math.max(0.6, spread * 0.18).toDouble();
    final minY = math.max(0.0, minValue - pad).toDouble();
    final maxY = maxValue + pad;
    final interval = resolveAxisInterval(minY, maxY, targetLabels: 5).interval;
    final yDecimals = interval < 0.25 ? 2 : 1;
    final step = math.max(1, (buckets.length / 4).ceil()).toInt();
    final spots = <FlSpot>[
      for (var i = 0; i < buckets.length; i++)
        FlSpot(i.toDouble(), buckets[i].avgKg),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (buckets.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: interval,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) {
            return FlLine(
              color: theme.colorScheme.onSurface.withOpacity(0.12),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 56,
              minIncluded: false,
              maxIncluded: false,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(yDecimals)} kg',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= buckets.length) {
                  return const SizedBox.shrink();
                }
                final isEdge = index == 0 || index == buckets.length - 1;
                if (!isEdge && index % step != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[index].label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.62),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.22,
            barWidth: 3,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                gradient.colors.first.withOpacity(0.95),
                gradient.colors.last.withOpacity(0.9),
              ],
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 3.6,
                    color: theme.colorScheme.surface,
                    strokeWidth: 2,
                    strokeColor: brandColor,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  brandColor.withOpacity(0.26),
                  brandColor.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round();
                if (index < 0 || index >= buckets.length) return null;
                final bucket = buckets[index];
                return LineTooltipItem(
                  '${bucket.label}\n${bucket.avgKg.toStringAsFixed(2)} kg · ${bucket.sampleCount}x',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
