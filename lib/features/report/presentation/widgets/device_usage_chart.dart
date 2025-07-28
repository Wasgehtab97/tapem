import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DeviceUsageChart extends StatefulWidget {
  final Map<String, int> usageData;

  const DeviceUsageChart({Key? key, required this.usageData}) : super(key: key);

  @override
  State<DeviceUsageChart> createState() => _DeviceUsageChartState();
}

class _DeviceUsageChartState extends State<DeviceUsageChart> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final entries = widget.usageData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final filtered = entries
        .where((e) => e.key.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    final maxBars = 20;
    var display = filtered;
    int otherSum = 0;
    if (filtered.length > maxBars) {
      display = filtered.take(maxBars - 1).toList();
      otherSum = filtered.skip(maxBars - 1).fold(0, (a, b) => a + b.value);
      display.add(MapEntry('Other', otherSum));
    }

    final bars = <BarChartGroupData>[];
    final gradient = [Colors.tealAccent, Colors.cyan, Colors.amber];
    for (var i = 0; i < display.length; i++) {
      final e = display[i];
      final colors = LinearGradient(colors: gradient).colors;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: e.value.toDouble(),
              width: 16,
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(colors: gradient),
            ),
          ],
        ),
      );
    }

    final maxY =
        display.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Gerät filtern',
          ),
          onChanged: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.2,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= display.length) return const SizedBox();
                      return RotatedBox(
                        quarterTurns: 1,
                        child: Text(
                          display[i].key,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, interval: maxY / 5),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: bars,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, __) {
                    final i = group.x.toInt();
                    final entry = display[i];
                    return BarTooltipItem(
                      '${entry.key}\n${entry.value} Sessions',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
