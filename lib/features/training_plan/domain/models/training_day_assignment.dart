class TrainingDayAssignment {
  const TrainingDayAssignment({
    required this.dateKey,
    required this.planId,
  });

  final String dateKey; // Format: yyyy-MM-dd (lokal)
  final String planId;

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'planId': planId,
    };
  }

  factory TrainingDayAssignment.fromJson(Map<String, dynamic> json) {
    return TrainingDayAssignment(
      dateKey: json['dateKey'] as String,
      planId: json['planId'] as String,
    );
  }
}

