import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain-Modell für eine einzelne Übungseinheit (Satz/Runde).
class ExerciseEntry extends Equatable {
  /// Firestore-Dokument-ID
  final String id;

  /// Name der Übung
  final String exercise;

  /// Anzahl der Sätze
  final int sets;

  /// Gewicht in kg
  final double weight;

  /// Wiederholungen pro Satz
  final int reps;

  /// Zeitpunkt der Erfassung (optional)
  final DateTime? trainingDate;

  const ExerciseEntry({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.weight,
    required this.reps,
    this.trainingDate,
  });

  /// Erstellt eine Instanz aus einer Firestore-Map.
  factory ExerciseEntry.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    DateTime? date;
    final ts = map['timestamp'];
    if (ts is Timestamp) {
      date = ts.toDate();
    } else if (ts is int) {
      date = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return ExerciseEntry(
      id: id,
      exercise: map['exercise'] as String? ?? '',
      sets: map['sets'] as int? ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: map['reps'] as int? ?? 0,
      trainingDate: date,
    );
  }

  /// Konvertiert zurück in Map für Firestore-Write.
  Map<String, dynamic> toMap() => {
        'exercise': exercise,
        'sets': sets,
        'weight': weight,
        'reps': reps,
        // FieldValue.serverTimestamp() nur bei Create – beim Update besser das Datum übernehmen
        'timestamp': FieldValue.serverTimestamp(),
      };

  @override
  List<Object?> get props => [id, exercise, sets, weight, reps, trainingDate];

  @override
  String toString() {
    final dateStr = trainingDate != null
        ? '${trainingDate!.day.toString().padLeft(2, '0')}.'
          '${trainingDate!.month.toString().padLeft(2, '0')}.'
          '${trainingDate!.year}'
        : 'kein Datum';
    return 'ExerciseEntry($exercise: $sets×, $weight kg, $reps Wdh. @ $dateStr)';
  }
}
