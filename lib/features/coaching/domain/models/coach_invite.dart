class CoachInvite {
  final String id;
  final String gymId;
  final String clientId;
  final String email;
  final String status; // pending, accepted, cancelled
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? coachId;

  const CoachInvite({
    required this.id,
    required this.gymId,
    required this.clientId,
    required this.email,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.coachId,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  CoachInvite copyWith({
    String? id,
    String? gymId,
    String? clientId,
    String? email,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    String? coachId,
  }) {
    return CoachInvite(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      clientId: clientId ?? this.clientId,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      coachId: coachId ?? this.coachId,
    );
  }

  factory CoachInvite.fromJson(Map<String, dynamic> json, {required String id}) {
    return CoachInvite(
      id: id,
      gymId: json['gymId'] as String,
      clientId: json['clientId'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      coachId: json['coachId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gymId': gymId,
      'clientId': clientId,
      'email': email,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      if (coachId != null) 'coachId': coachId,
    };
  }
}

