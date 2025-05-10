import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> historyData = [];
  bool isLoading = true;
  String? userId;
  String? deviceId;
  String? exercise;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchHistory();
  }

  Future<void> _loadUserAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    userId = prefs.getString('userId');

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      deviceId = args['deviceId']?.toString();
      exercise = args['exercise']?.toString();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ungültige Geräte-/Übungsparameter")),
      );
      return;
    }

    if (userId != null) {
      await _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiService().getTrainingSessions(
        userId: userId!,
        deviceId: deviceId,
        exercise: exercise,
      );
      if (!mounted) return;
      setState(() {
        historyData = data.map((e) => Map<String, dynamic>.from(e)).toList();
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("Fehler beim Abrufen der Trainingshistorie: $error");
    }
  }

  String _formatLocalDate(dynamic raw) {
    DateTime d;
    if (raw is Timestamp) {
      d = raw.toDate();
    } else if (raw is DateTime) {
      d = raw;
    } else {
      d = DateTime.parse(raw.toString());
    }
    d = d.toUtc().add(const Duration(hours: 1));
    String pad(int n) => n.toString().padLeft(2, '0');
    return "${d.year}-${pad(d.month)}-${pad(d.day)}";
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final out = <String, List<Map<String, dynamic>>>{};
    for (var session in historyData) {
      final key = _formatLocalDate(session['training_date']);
      out.putIfAbsent(key, () => []).add(session);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    final chartValues = dates.map((date) {
      final sessions = grouped[date]!;
      double weightedSum = 0;
      int repSum = 0;
      for (var sess in sessions) {
        for (var s in sess['data'] as List<dynamic>) {
          final w = double.tryParse(s['weight'].toString()) ?? 0;
          final r = int.tryParse(s['reps'].toString()) ?? 0;
          weightedSum += w * (1 + r / 30) * r;
          repSum += r;
        }
      }
      return repSum > 0 ? weightedSum / repSum : 0.0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trainingshistorie',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A1A1A),
              Color(0xFF333333),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Leistungsverlauf',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 300,
                          child: LineChart(
                            LineChartData(
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    getTitlesWidget: (val, meta) {
                                      final idx = val.toInt();
                                      if (idx >= 0 &&
                                          idx < dates.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            dates[idx],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 10,
                                    getTitlesWidget: (val, meta) =>
                                        Text(
                                      val.toInt().toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 10,
                                            color: Theme.of(context)
                                                .colorScheme.secondary,
                                          ),
                                    ),
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles:
                                      SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    chartValues.length,
                                    (i) => FlSpot(
                                      i.toDouble(),
                                      chartValues[i],
                                    ),
                                  ),
                                  isCurved: true,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (grouped.isNotEmpty)
                      ...dates.map((date) {
                        final allSets = <Map<String, dynamic>>[];
                        for (var sess in grouped[date]!) {
                          for (var s in sess['data'] as List<dynamic>) {
                            allSets.add(Map<String, dynamic>.from(s));
                          }
                        }
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  date,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme.secondary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: [
                                      DataColumn(
                                        label: Text(
                                          'Satz',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Kg',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          'Wdh',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                    rows: allSets.map((setMap) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              setMap['sets'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              setMap['weight']
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              setMap['reps'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      Center(
                        child: Text(
                          "Keine Trainingshistorie vorhanden.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
