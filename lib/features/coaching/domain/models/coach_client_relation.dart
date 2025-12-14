class CoachClientRelation {
  final String id;
  final String gymId;
  final String coachId;
  final String clientId;
  final String status; // pending, active, ended, rejected
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? endedAt;
  final String? endedReason;
  final String? note;

  const CoachClientRelation({
    required this.id,
    required this.gymId,
    required this.coachId,
    required this.clientId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.endedAt,
    this.endedReason,
    this.note,
  });

  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get isRejected => status == 'rejected';

  CoachClientRelation copyWith({
    String? id,
    String? gymId,
    String? coachId,
    String? clientId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? endedAt,
    String? endedReason,
    String? note,
  }) {
    return CoachClientRelation(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      endedAt: endedAt ?? this.endedAt,
      endedReason: endedReason ?? this.endedReason,
      note: note ?? this.note,
    );
  }

  factory CoachClientRelation.fromJson(Map<String, dynamic> json, {required String id}) {
    return CoachClientRelation(
      id: id,
      gymId: json['gymId'] as String,
      coachId: json['coachId'] as String,
      clientId: json['clientId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      endedReason: json['endedReason'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gymId': gymId,
      'coachId': coachId,
      'clientId': clientId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
      if (endedReason != null) 'endedReason': endedReason,
      if (note != null) 'note': note,
    };
  }
}

