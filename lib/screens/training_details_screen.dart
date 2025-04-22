import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingDetailsScreen extends StatefulWidget {
  final String selectedDate; // "YYYY-MM-DD"
  const TrainingDetailsScreen({Key? key, required this.selectedDate})
      : super(key: key);

  @override
  _TrainingDetailsScreenState createState() =>
      _TrainingDetailsScreenState();
}

class _TrainingDetailsScreenState extends State<TrainingDetailsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> setEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchTrainingDetails();
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }

  String _formatDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _toGermanDate(dynamic inDate) {
    DateTime d;
    if (inDate is Timestamp) d = inDate.toDate();
    else if (inDate is DateTime) d = inDate;
    else d = DateTime.parse(inDate.toString());
    final offset = (d.month >= 4 && d.month <= 9) ? 2 : 1;
    final gd = d.toUtc().add(Duration(hours: offset));
    return _formatDate(gd);
  }

  Future<void> _fetchTrainingDetails() async {
    final uid = await _getUserId();
    if (uid.isEmpty) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('training_history')
          .where('user_id', isEqualTo: uid)
          .get();

      final temp = <Map<String, dynamic>>[];
      for (var doc in snap.docs) {
        final m = doc.data() as Map<String, dynamic>;
        if (_toGermanDate(m['training_date']) ==
            widget.selectedDate) {
          for (var s in m['data'] as List<dynamic>) {
            temp.add(Map<String, dynamic>.from(s));
          }
        }
      }
      setEntries = temp;
    } catch (e) {
      debugPrint("Fehler beim Laden der Details: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByExercise() {
    final out = <String, List<Map<String, dynamic>>>{};
    for (var e in setEntries) {
      final ex = e['exercise'] ?? 'Unbekannte Übung';
      out.putIfAbsent(ex, () => []).add(e);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupByExercise();
    return Scaffold(
      appBar: AppBar(title: Text("Training am ${widget.selectedDate}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? const Center(child: Text("Keine Daten für diesen Tag."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: groups.entries.map((e) {
                      final list = e.value;
                      list.sort((a, b) {
                        final ai = a['sets'] as int? ?? 0;
                        final bi = b['sets'] as int? ?? 0;
                        return ai.compareTo(bi);
                      });
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Satz')),
                                    DataColumn(label: Text('Kg')),
                                    DataColumn(label: Text('Wdh')),
                                  ],
                                  rows: list.map((row) {
                                    return DataRow(cells: [
                                      DataCell(Text(row['sets'].toString())),
                                      DataCell(Text(row['weight'].toString())),
                                      DataCell(Text(row['reps'].toString())),
                                    ]);
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
