import 'package:cloud_firestore/cloud_firestore.dart';

class Survey {
  final String id;
  final String title;
  final List<String> options;
  final bool open;
  final DateTime createdAt;

  Survey({
    required this.id,
    required this.title,
    required this.options,
    required this.open,
    required this.createdAt,
  });

  factory Survey.fromMap(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else {
      createdAt = DateTime.now();
    }
    return Survey(
      id: id,
      title: data['title'] as String? ?? '',
      options: List<String>.from(data['options'] as List<dynamic>? ?? []),
      open: data['status'] == 'offen',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'options': options,
      'status': open ? 'offen' : 'abgeschlossen',
      'createdAt': createdAt,
    };
  }
}

class SurveyAnswer {
  final String id;
  final String surveyId;
  final String userId;
  final String selectedOption;
  final DateTime timestamp;

  SurveyAnswer({
    required this.id,
    required this.surveyId,
    required this.userId,
    required this.selectedOption,
    required this.timestamp,
  });

  factory SurveyAnswer.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['timestamp'];
    DateTime time;
    if (ts is Timestamp) {
      time = ts.toDate();
    } else if (ts is DateTime) {
      time = ts;
    } else {
      time = DateTime.now();
    }
    return SurveyAnswer(
      id: id,
      surveyId: data['surveyId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      selectedOption: data['selectedOption'] as String? ?? '',
      timestamp: time,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'userId': userId,
      'selectedOption': selectedOption,
      'timestamp': timestamp,
    };
  }
}
