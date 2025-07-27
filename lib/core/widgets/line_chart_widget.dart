import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/design_tokens.dart';

/// A reusable line chart widget with gradient stroke and tooltips.
class TimeSeriesLineChart extends StatelessWidget {
  const TimeSeriesLineChart({
    Key? key,
    required this.points,
    this.height = 200,
  }) : super(key: key);

  /// List of data points. The x value is interpreted as an index; if you
  /// need dates or times, map them to indices outside this widget.
  final List<double> points;

  /// Chart height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
                  final index = value.toInt();
                  return Text(
                    labels[index % labels.length],
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
                interval: 1,
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: points.isEmpty ? 0 : (points.reduce((a, b) => a > b ? a : b) * 1.2),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i])],
              isCurved: true,
              color: null,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentTurquoise,
                  AppColors.accentAmber,
                ],
              ),
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.accentTurquoise.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  return LineTooltipItem(
                    touchedSpot.y.toStringAsFixed(1),
                    TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFontSizes.body,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
