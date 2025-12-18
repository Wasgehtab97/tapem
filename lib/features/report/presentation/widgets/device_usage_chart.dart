import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/core/utils/chart_interval.dart';
import 'package:tapem/l10n/app_localizations.dart';

class DeviceUsageChart extends StatefulWidget {
  final List<DeviceUsageStat> usageData;
  final ReportState state;
  final String? errorMessage;
  final DeviceUsageRange usageRange;
  final ValueChanged<DeviceUsageRange> onRangeSelected;

  const DeviceUsageChart({
    super.key,
    required this.usageData,
    required this.state,
    this.errorMessage,
    required this.usageRange,
    required this.onRangeSelected,
  });

  @override
  State<DeviceUsageChart> createState() => _DeviceUsageChartState();
}

class _DeviceUsageChartState extends State<DeviceUsageChart> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (widget.state == ReportState.loading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.state == ReportState.error) {
      return SizedBox(
        height: 250,
        child: Center(child: Text(widget.errorMessage ?? 'Ein Fehler ist aufgetreten')),
      );
    }

    if (widget.usageData.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('Keine Daten verfügbar')),
      );
    }

    // Sort by sessions descending and take top 7 for the chart to avoid clutter
    final entries = List<DeviceUsageStat>.from(widget.usageData)
      ..sort((a, b) => b.sessions.compareTo(a.sessions));

    final query = _filter.trim().toLowerCase();
    final filtered = query.isEmpty
        ? entries
        : entries
            .where((e) => e.name.toLowerCase().contains(query) ||
                e.description.toLowerCase().contains(query))
            .toList();

    final bool hasBaseData = entries.isNotEmpty;
    final bool hasFilteredData = filtered.isNotEmpty;

    final chartContent = _buildChartContent(
      context,
      loc,
      theme,
      filtered,
      hasBaseData,
      hasFilteredData,
    );

    final rangeChips = DeviceUsageRange.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              for (final range in rangeChips)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(_labelForRange(loc, range)),
                    selected: widget.usageRange == range,
                    onSelected: (selected) {
                      if (selected) {
                        widget.onRangeSelected(range);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: loc.reportDeviceFilterHint,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withOpacity(theme.brightness == Brightness.dark ? 0.24 : 0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              borderSide: BorderSide.none,
            ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: chartContent,
        ),
      ],
    );
  }

  String _labelForRange(AppLocalizations loc, DeviceUsageRange range) {
    switch (range) {
      case DeviceUsageRange.last7Days:
        return loc.reportUsageRange7Days;
      case DeviceUsageRange.last30Days:
        return loc.reportUsageRange30Days;
      case DeviceUsageRange.last90Days:
        return loc.reportUsageRange90Days;
      case DeviceUsageRange.last365Days:
        return loc.reportUsageRange365Days;
      case DeviceUsageRange.all:
        return loc.reportUsageRangeAll;
    }
  }

  Widget _buildChartContent(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    List<DeviceUsageStat> filtered,
    bool hasBaseData,
    bool hasFilteredData,
  ) {
    final textStyle = theme.textTheme.bodySmall ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final valueStyle = theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    if (widget.state == ReportState.loading && !hasBaseData) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.state == ReportState.error && !hasBaseData) {
      final message = widget.errorMessage ?? loc.reportDeviceUsageError;
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (!hasBaseData) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            loc.reportDeviceUsageEmpty,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!hasFilteredData) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            loc.reportDeviceUsageNoMatches,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maxSessions = filtered
        .map((e) => e.sessions)
        .fold<int>(0, (previousValue, element) => math.max(previousValue, element));
    final double chartMax = math.max(1, maxSessions.toDouble());
    final interval = resolveAxisInterval(0, chartMax, targetLabels: 5);
    final ticks = _buildTicks(chartMax, interval);

    return _UsageChartArea(
      stats: filtered,
      maxValue: chartMax,
      ticks: ticks,
      nameStyle: textStyle,
      valueStyle: valueStyle,
      valueFormatter: loc.reportDeviceUsageSessions,
      onBarTap: (stat) => _handleBarTap(context, stat),
    );
  }

  List<double> _buildTicks(double maxValue, AxisInterval interval) {
    if (!interval.showTitles) {
      return [0, maxValue];
    }
    final ticks = <double>{0, maxValue};
    final double step =
        interval.interval <= 0 ? 1.0 : interval.interval.toDouble();
    double current = step;
    while (current < maxValue) {
      ticks.add(double.parse(current.toStringAsFixed(2)));
      current += step;
    }
    final sorted = ticks.toList()..sort();
    return sorted;
  }

  void _handleBarTap(BuildContext context, DeviceUsageStat stat) {
    if (!mounted) {
      return;
    }
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                loc.reportDeviceUsageSessions(stat.sessions),
                style: theme.textTheme.bodyMedium,
              ),
              if (stat.description.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  stat.description.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _UsageChartArea extends StatelessWidget {
  const _UsageChartArea({
    required this.stats,
    required this.maxValue,
    required this.ticks,
    required this.nameStyle,
    required this.valueStyle,
    required this.valueFormatter,
    required this.onBarTap,
  });

  final List<DeviceUsageStat> stats;
  final double maxValue;
  final List<double> ticks;
  final TextStyle nameStyle;
  final TextStyle valueStyle;
  final String Function(int) valueFormatter;
  final void Function(DeviceUsageStat stat) onBarTap;

  static const double _axisWidth = 64;
  static const double _topPadding = 16;
  static const double _bottomPadding = 56;
  static const double _horizontalPadding = 16;
  static const double _barWidth = 104;
  static const double _barSpacing = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisLabelColor = theme.textTheme.labelSmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.72);
    final gridColor = axisLabelColor.withOpacity(0.25);
    final totalBarsWidth =
        stats.length * _barWidth + math.max(0, stats.length - 1) * _barSpacing;
    final contentWidth = totalBarsWidth + _horizontalPadding * 2;
    final chartHeight = 260 + _topPadding + _bottomPadding;

    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final verticalChartHeight = chartHeight - _topPadding - _bottomPadding;
    final barGeometries = <_BarGeometry>[
      for (var i = 0; i < stats.length; i++)
        _createGeometry(
          stat: stats[i],
          index: i,
          safeMax: safeMax,
          verticalChartHeight: verticalChartHeight,
          chartHeight: chartHeight,
        ),
    ];

    return SizedBox(
      height: chartHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(width: _axisWidth),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = math.max(contentWidth, constraints.maxWidth);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            final stat = _hitTestBar(details.localPosition, barGeometries);
                            if (stat != null) {
                              onBarTap(stat);
                            }
                          },
                          child: CustomPaint(
                            size: Size(width, chartHeight),
                          painter: _UsageChartPainter(
                            bars: barGeometries,
                            maxValue: maxValue,
                            ticks: ticks,
                            barWidth: _barWidth,
                            barSpacing: _barSpacing,
                            topPadding: _topPadding,
                            bottomPadding: _bottomPadding,
                            horizontalPadding: _horizontalPadding,
                            gradient: AppGradients.progress,
                            nameStyle: nameStyle,
                            valueStyle: valueStyle,
                            gridColor: gridColor,
                            valueFormatter: valueFormatter,
                          ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _axisWidth,
            child: CustomPaint(
              painter: _UsageAxisPainter(
                ticks: ticks,
                maxValue: maxValue,
                topPadding: _topPadding,
                bottomPadding: _bottomPadding,
                labelStyle: nameStyle.copyWith(
                  color: axisLabelColor,
                  fontWeight: FontWeight.w500,
                ),
                gridColor: gridColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BarGeometry _createGeometry({
    required DeviceUsageStat stat,
    required int index,
    required double safeMax,
    required double verticalChartHeight,
    required double chartHeight,
  }) {
    final left = _horizontalPadding + index * (_barWidth + _barSpacing);
    final clampedSessions = stat.sessions.toDouble().clamp(0, safeMax);
    final normalized = safeMax == 0 ? 0 : clampedSessions / safeMax;
    final barTop = _topPadding + (1 - normalized) * verticalChartHeight;
    final barBottom = chartHeight - _bottomPadding;
    final double barHeight = math.max(4.0, barBottom - barTop);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, barBottom - barHeight, _barWidth, barHeight),
      const Radius.circular(AppRadius.card),
    );
    return _BarGeometry(stat: stat, rect: rect);
  }

  DeviceUsageStat? _hitTestBar(Offset position, List<_BarGeometry> geometries) {
    for (final bar in geometries) {
      if (bar.rect.contains(position)) {
        return bar.stat;
      }
    }
    return null;
  }
}

class _UsageAxisPainter extends CustomPainter {
  _UsageAxisPainter({
    required this.ticks,
    required this.maxValue,
    required this.topPadding,
    required this.bottomPadding,
    required this.labelStyle,
    required this.gridColor,
  });

  final List<double> ticks;
  final double maxValue;
  final double topPadding;
  final double bottomPadding;
  final TextStyle labelStyle;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - topPadding - bottomPadding;
    final double safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final axisPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final baselineY = size.height - bottomPadding;
    canvas.drawLine(
      Offset(size.width - 4, baselineY),
      Offset(size.width - 4, topPadding),
      axisPaint,
    );

    for (final tick in ticks) {
      final y = _yForValue(
        tick,
        chartHeight: chartHeight,
        safeMax: safeMax,
        topPadding: topPadding,
      );
      canvas.drawLine(
        Offset(size.width - 8, y),
        Offset(size.width - 4, y),
        axisPaint,
      );

      final formatted = _formatTick(tick);
      final painter = TextPainter(
        text: TextSpan(text: formatted, style: labelStyle),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 12);
      painter.paint(
        canvas,
        Offset(size.width - painter.width - 12, y - painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _UsageAxisPainter oldDelegate) {
    return ticks != oldDelegate.ticks ||
        maxValue != oldDelegate.maxValue ||
        labelStyle != oldDelegate.labelStyle ||
        gridColor != oldDelegate.gridColor;
  }

  String _formatTick(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _UsageChartPainter extends CustomPainter {
  _UsageChartPainter({
    required this.bars,
    required this.maxValue,
    required this.ticks,
    required this.barWidth,
    required this.barSpacing,
    required this.topPadding,
    required this.bottomPadding,
    required this.horizontalPadding,
    required this.gradient,
    required this.nameStyle,
    required this.valueStyle,
    required this.gridColor,
    required this.valueFormatter,
  });

  final List<_BarGeometry> bars;
  final double maxValue;
  final List<double> ticks;
  final double barWidth;
  final double barSpacing;
  final double topPadding;
  final double bottomPadding;
  final double horizontalPadding;
  final LinearGradient gradient;
  final TextStyle nameStyle;
  final TextStyle valueStyle;
  final Color gridColor;
  final String Function(int) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - topPadding - bottomPadding;
    final double safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw background grid lines.
    for (final tick in ticks) {
      final y = _yForValue(
        tick,
        chartHeight: chartHeight,
        safeMax: safeMax,
        topPadding: topPadding,
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final baselineY = size.height - bottomPadding;
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      gridPaint,
    );

    for (final bar in bars) {
      final stat = bar.stat;
      final barRect = bar.rect;
      final left = barRect.left;
      final barHeight = barRect.height;
      final paint = Paint()
        ..shader = gradient.createShader(barRect.outerRect);
      canvas.drawRRect(barRect, paint);

      // Render usage value above the bar.
      final valuePainter = TextPainter(
        text: TextSpan(
          text: valueFormatter(stat.sessions),
          style: valueStyle,
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth + 16);
      final valueTop = math.max(
        topPadding,
        barRect.top - valuePainter.height - 6,
      );
      valuePainter.paint(
        canvas,
        Offset(left + (barWidth - valuePainter.width) / 2, valueTop),
      );

      if (stat.sessions > 10) {
        final namePainter = TextPainter(
          text: TextSpan(
            text: stat.name,
            style: nameStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: barWidth - 24);

        final availableHeight = barHeight - 20;
        if (namePainter.height <= availableHeight) {
          final labelTop = barRect.top + (barHeight - namePainter.height) / 2;
          namePainter.paint(
            canvas,
            Offset(left + (barWidth - namePainter.width) / 2, labelTop),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return bars != oldDelegate.bars ||
        maxValue != oldDelegate.maxValue ||
        nameStyle != oldDelegate.nameStyle ||
        gridColor != oldDelegate.gridColor;
  }
}

class _BarGeometry {
  const _BarGeometry({required this.stat, required this.rect});

  final DeviceUsageStat stat;
  final RRect rect;
}

double _yForValue(
  double value, {
  required double chartHeight,
  required double safeMax,
  required double topPadding,
}) {
  final clamped = value.clamp(0, safeMax);
  final normalized = safeMax == 0 ? 0 : clamped / safeMax;
  return topPadding + (1 - normalized) * chartHeight;
}
