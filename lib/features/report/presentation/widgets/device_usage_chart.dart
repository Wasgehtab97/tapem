import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/providers/report_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/chart_interval.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/device_usage_stat.dart';

class DeviceUsageChart extends StatefulWidget {
  final List<DeviceUsageStat> usageData;
  final ReportState state;
  final String? errorMessage;

  const DeviceUsageChart({
    super.key,
    required this.usageData,
    required this.state,
    this.errorMessage,
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
    final entries = [...widget.usageData]
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: loc.reportDeviceFilterHint,
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant
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
    final descriptionStyle = theme.textTheme.labelSmall ??
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w500);
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
      descriptionStyle: descriptionStyle,
      valueStyle: valueStyle,
      valueFormatter: loc.reportDeviceUsageSessions,
    );
  }

  List<double> _buildTicks(double maxValue, AxisInterval interval) {
    if (!interval.showTitles) {
      return [0, maxValue];
    }
    final ticks = <double>{0, maxValue};
    final step = interval.interval <= 0 ? 1 : interval.interval;
    double current = step;
    while (current < maxValue) {
      ticks.add(double.parse(current.toStringAsFixed(2)));
      current += step;
    }
    final sorted = ticks.toList()..sort();
    return sorted;
  }
}

class _UsageChartArea extends StatelessWidget {
  const _UsageChartArea({
    required this.stats,
    required this.maxValue,
    required this.ticks,
    required this.nameStyle,
    required this.descriptionStyle,
    required this.valueStyle,
    required this.valueFormatter,
  });

  final List<DeviceUsageStat> stats;
  final double maxValue;
  final List<double> ticks;
  final TextStyle nameStyle;
  final TextStyle descriptionStyle;
  final TextStyle valueStyle;
  final String Function(int) valueFormatter;

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
    final descriptionColor = descriptionStyle.color ??
        Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.8 : 0.7);

    final totalBarsWidth =
        stats.length * _barWidth + math.max(0, stats.length - 1) * _barSpacing;
    final contentWidth = totalBarsWidth + _horizontalPadding * 2;
    final chartHeight = 260 + _topPadding + _bottomPadding;

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
                        child: CustomPaint(
                          size: Size(width, chartHeight),
                          painter: _UsageChartPainter(
                            stats: stats,
                            maxValue: maxValue,
                            ticks: ticks,
                            barWidth: _barWidth,
                            barSpacing: _barSpacing,
                            topPadding: _topPadding,
                            bottomPadding: _bottomPadding,
                            horizontalPadding: _horizontalPadding,
                            gradient: AppGradients.progress,
                            nameStyle: nameStyle,
                            descriptionStyle:
                                descriptionStyle.copyWith(color: descriptionColor),
                            valueStyle: valueStyle,
                            gridColor: gridColor,
                            valueFormatter: valueFormatter,
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
    final safeMax = maxValue <= 0 ? 1 : maxValue;
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
    required this.stats,
    required this.maxValue,
    required this.ticks,
    required this.barWidth,
    required this.barSpacing,
    required this.topPadding,
    required this.bottomPadding,
    required this.horizontalPadding,
    required this.gradient,
    required this.nameStyle,
    required this.descriptionStyle,
    required this.valueStyle,
    required this.gridColor,
    required this.valueFormatter,
  });

  final List<DeviceUsageStat> stats;
  final double maxValue;
  final List<double> ticks;
  final double barWidth;
  final double barSpacing;
  final double topPadding;
  final double bottomPadding;
  final double horizontalPadding;
  final LinearGradient gradient;
  final TextStyle nameStyle;
  final TextStyle descriptionStyle;
  final TextStyle valueStyle;
  final Color gridColor;
  final String Function(int) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - topPadding - bottomPadding;
    final safeMax = maxValue <= 0 ? 1 : maxValue;
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

    for (var i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final left = horizontalPadding + i * (barWidth + barSpacing);
      final barTop = _yForValue(
        stat.sessions.toDouble(),
        chartHeight: chartHeight,
        safeMax: safeMax,
        topPadding: topPadding,
      );
      final barBottom = size.height - bottomPadding;
      final barHeight = math.max(4, barBottom - barTop);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, barBottom - barHeight, barWidth, barHeight),
        const Radius.circular(AppRadius.card),
      );
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

      final namePainter = TextPainter(
        text: TextSpan(text: stat.name, style: nameStyle.copyWith(color: Colors.black.withOpacity(0.85))),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: barWidth - 16);

      final descriptionPainter = stat.description.isEmpty
          ? null
          : (TextPainter(
              text: TextSpan(
                text: stat.description,
                style: descriptionStyle,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 2,
              ellipsis: '…',
            )..layout(maxWidth: barWidth - 16));

      final combinedHeight = namePainter.height +
          (descriptionPainter?.height ?? 0) +
          (descriptionPainter != null ? 6 : 0);
      final hasRoomInside = barHeight - 24 >= combinedHeight;

      double textTop;
      if (hasRoomInside) {
        textTop = barRect.top + (barHeight - combinedHeight) / 2;
      } else {
        textTop = barRect.bottom + 8;
      }

      namePainter.paint(
        canvas,
        Offset(left + (barWidth - namePainter.width) / 2, textTop),
      );

      if (descriptionPainter != null) {
        final descTop = textTop + namePainter.height + 6;
        descriptionPainter.paint(
          canvas,
          Offset(left + (barWidth - descriptionPainter.width) / 2, descTop),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return stats != oldDelegate.stats ||
        maxValue != oldDelegate.maxValue ||
        nameStyle != oldDelegate.nameStyle ||
        descriptionStyle != oldDelegate.descriptionStyle ||
        gridColor != oldDelegate.gridColor;
  }
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
