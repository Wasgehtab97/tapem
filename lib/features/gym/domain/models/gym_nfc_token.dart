class GymNfcToken {
  final String id;
  final String gymId;
  final String gymCode;
  final bool isActive;

  GymNfcToken({
    required this.id,
    required this.gymId,
    required this.gymCode,
    required this.isActive,
  });

  factory GymNfcToken.fromMap(String id, Map<String, dynamic> data) {
    return GymNfcToken(
      id: id,
      gymId: data['gymId'] as String? ?? '',
      gymCode: data['gymCode'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}
