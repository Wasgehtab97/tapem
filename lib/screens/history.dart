import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> historyData = [];
  bool isLoading = true;
  int? userId;
  int? deviceId;
  String? exercise;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchHistory();
  }

  Future<void> _loadUserAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      userId = prefs.getInt('userId');
    });
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      deviceId = args['deviceId'];
      if (args.containsKey('exercise')) {
        exercise = args['exercise'];
      }
    } else if (args is int) {
      deviceId = args;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ungültige Geräte-ID")),
        );
      }
      return;
    }
    if (userId != null) {
      await _fetchHistory();
    }
  }

  /// Parst das Datum, rechnet in UTC+1 um und formatiert als "YYYY-MM-DD".
  String _formatLocalDate(dynamic dateInput) {
    DateTime d;
    if (dateInput is String) {
      d = DateTime.parse(dateInput).toUtc().add(const Duration(hours: 1));
    } else if (dateInput is DateTime) {
      d = dateInput.toUtc().add(const Duration(hours: 1));
    } else {
      d = DateTime.now().toUtc().add(const Duration(hours: 1));
    }
    String pad(int n) => n.toString().padLeft(2, '0');
    return "${d.year}-${pad(d.month)}-${pad(d.day)}";
  }

  Map<String, List<dynamic>> _groupHistoryByDate() {
    Map<String, List<dynamic>> grouped = {};
    for (var entry in historyData) {
      String dateFormatted = _formatLocalDate(entry['training_date']);
      grouped.putIfAbsent(dateFormatted, () => []).add(entry);
    }
    return grouped;
  }

  List<String> _getSortedDates(Map<String, List<dynamic>> grouped) {
    List<String> dates = grouped.keys.toList();
    dates.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    return dates;
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiService().getHistory(
        userId!,
        deviceId: deviceId,
        exercise: exercise,
      );
      if (!mounted) return;
      setState(() {
        historyData = data;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      debugPrint("Fehler beim Abrufen der Trainingshistorie: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupHistoryByDate();
    final sortedDates = _getSortedDates(groupedData);
    List<String> chartLabels = sortedDates;
    List<double> chartDataPoints = sortedDates.map((date) {
      final sessions = groupedData[date]!;
      double totalWeighted1RM = 0.0;
      int totalReps = 0;
      for (var entry in sessions) {
        double weight = double.tryParse(entry['weight'].toString()) ?? 0.0;
        int reps = int.tryParse(entry['reps'].toString()) ?? 0;
        totalWeighted1RM += weight * (1 + reps / 30) * reps;
        totalReps += reps;
      }
      return totalReps > 0 ? totalWeighted1RM / totalReps : 0.0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trainingshistorie',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Leistungsverlauf',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                                    getTitlesWidget: (value, meta) {
                                      int index = value.toInt();
                                      if (index >= 0 && index < chartLabels.length) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            chartLabels[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  color: Theme.of(context)
                                                      .colorScheme.secondary,
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
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
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
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(show: true),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    chartDataPoints.length,
                                    (index) => FlSpot(
                                      index.toDouble(),
                                      chartDataPoints[index],
                                    ),
                                  ),
                                  isCurved: true,
                                  color: Colors.teal,
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
                    if (groupedData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sortedDates.map((date) {
                          List<dynamic> sessions = groupedData[date]!;
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                              .colorScheme
                                              .secondary,
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
                                                      .colorScheme.secondary,
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
                                                      .colorScheme.secondary,
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
                                                      .colorScheme.secondary,
                                                ),
                                          ),
                                        ),
                                      ],
                                      rows: sessions.map<DataRow>((entry) {
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(
                                              entry['sets'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            )),
                                            DataCell(Text(
                                              entry['weight'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            )),
                                            DataCell(Text(
                                              entry['reps'].toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            )),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
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
