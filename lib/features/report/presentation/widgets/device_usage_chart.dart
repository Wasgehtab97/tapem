// lib/features/report/presentation/widgets/device_usage_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tapem/features/device/domain/models/device.dart';

class DeviceUsageChart extends StatelessWidget {
  /// Liste aller Geräte im aktuellen Gym
  final List<Device> devices;

  /// Nutzungszahlen, key = device.uid, value = Anzahl aller Sessions
  final Map<String, int> usageCounts;

  const DeviceUsageChart({
    required this.devices,
    required this.usageCounts,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Erzeuge eine Bar pro Device (auch wenn count = 0)
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < devices.length; i++) {
      final device   = devices[i];
      final count    = usageCounts[device.uid] ?? 0;
      final barColor = Theme.of(context).colorScheme.primary;

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              width: 16.0,
              color: barColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (usageCounts.values.isEmpty
                ? 1
                : usageCounts.values.reduce((a, b) => a > b ? a : b)
                    .toDouble()) *
            1.2, // etwas Kopfraum
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 1)),
          rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final device = devices[group.x.toInt()];
              final sessions = rod.toY.toInt();
              return BarTooltipItem(
                '${device.name}\n$sessions Sessions',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}
