// lib/domain/models/report_entry.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Eintrag für Report-Diagramme.
class ReportEntry {
  final String id;
  final DateTime date;
  final int sessionCount;
  final double totalVolume;

  const ReportEntry({
    required this.id,
    required this.date,
    required this.sessionCount,
    required this.totalVolume,
  });

  factory ReportEntry.fromMap(Map<String, dynamic> map, {required String id}) {
    return ReportEntry(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      sessionCount: map['session_count'] as int,
      totalVolume: (map['total_volume'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'session_count': sessionCount,
        'total_volume': totalVolume,
      };
}
