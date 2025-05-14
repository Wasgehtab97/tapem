/// Kurzdaten zu einem Klienten.
class ClientInfo {
  final String id;
  final String name;
  final DateTime? joinedAt;

  const ClientInfo({
    required this.id,
    required this.name,
    this.joinedAt,
  });

  factory ClientInfo.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return ClientInfo(
      id: id,
      name: map['name'] as String,
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
      };
}
