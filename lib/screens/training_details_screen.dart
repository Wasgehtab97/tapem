import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';

class TrainingDetailsScreen extends StatefulWidget {
  final String selectedDate; // Format "YYYY-MM-DD" in deutscher Zeit
  const TrainingDetailsScreen({Key? key, required this.selectedDate}) : super(key: key);

  @override
  _TrainingDetailsScreenState createState() => _TrainingDetailsScreenState();
}

class _TrainingDetailsScreenState extends State<TrainingDetailsScreen> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  List<dynamic> trainingEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchTrainingDetails();
  }

  /// Formatiert ein Datum als "YYYY-MM-DD".
  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  /// Konvertiert ein Datum in die deutsche Zeitzone (Europe/Berlin)
  /// unter Berücksichtigung eines einfachen DST-Checks und gibt es als "YYYY-MM-DD" zurück.
  String _formatLocalDate(dynamic dateInput) {
    DateTime d;
    if (dateInput is String) {
      d = DateTime.parse(dateInput).toUtc().add(const Duration(hours: 1));
    } else if (dateInput is DateTime) {
      d = dateInput.toUtc().add(const Duration(hours: 1));
    } else {
      d = DateTime.now().toUtc().add(const Duration(hours: 1));
    }
    return _formatDate(d);
  }

  Future<void> _fetchTrainingDetails() async {
    try {
      final userId = await _getUserId();
      final history = await apiService.getHistory(userId);
      
      // Debug-Ausgaben: Rohdaten und konvertierte Datumseinträge
      for (var entry in history) {
        debugPrint("Raw DB date: ${entry['training_date']}");
        try {
          String converted = _formatLocalDate(entry['training_date']);
          debugPrint("Converted date: $converted");
        } catch (e) {
          debugPrint("Fehler beim Parsen: $e");
        }
      }
      debugPrint("Selected Date: ${widget.selectedDate}");
      
      // Filtere alle Einträge, deren Datum (in deutscher Zeit) exakt dem ausgewählten Datum entspricht.
      final filtered = history.where((entry) {
        try {
          String converted = _formatLocalDate(entry['training_date']);
          return converted == widget.selectedDate;
        } catch (e) {
          return false;
        }
      }).toList();
      
      debugPrint("Filtered entries count: ${filtered.length}");
      
      setState(() {
        trainingEntries = filtered;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Fehler beim Abrufen der Trainingsdetails: $error");
    }
  }

  Future<int> _getUserId() async {
    // Lese die userId aus den SharedPreferences aus.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId') ?? 0; // 0 als Fallback, falls nichts gefunden wurde.
  }

  /// Gruppiert die Trainingseinträge nach Übungsname.
  Map<String, List<dynamic>> _groupEntriesByExercise(List<dynamic> entries) {
    final Map<String, List<dynamic>> groups = {};
    for (var entry in entries) {
      final exercise = entry['exercise'] ?? 'Unbekannte Übung';
      groups.putIfAbsent(exercise, () => []).add(entry);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Training am ${widget.selectedDate}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trainingEntries.isEmpty
              ? Center(child: Text("Keine Trainingsdaten für diesen Tag gefunden."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _groupEntriesByExercise(trainingEntries)
                        .entries
                        .map((exerciseGroup) {
                      final exerciseName = exerciseGroup.key;
                      final sets = exerciseGroup.value;
                      sets.sort((a, b) {
                        final aSet = a['setNumber'] ?? a['sets'] ?? 0;
                        final bSet = b['setNumber'] ?? b['sets'] ?? 0;
                        return aSet.compareTo(bSet);
                      });
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exerciseName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
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
                                            ?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Kg',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Wdh',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                  rows: sets.map<DataRow>((setEntry) {
                                    final setNumber = setEntry['setNumber'] ?? setEntry['sets'] ?? '?';
                                    final reps = setEntry['reps'].toString();
                                    final weight = setEntry['weight'].toString();
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(setNumber.toString(), style: Theme.of(context).textTheme.bodyMedium)),
                                        DataCell(Text(weight, style: Theme.of(context).textTheme.bodyMedium)),
                                        DataCell(Text(reps, style: Theme.of(context).textTheme.bodyMedium)),
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
                  ),
                ),
    );
  }
}
