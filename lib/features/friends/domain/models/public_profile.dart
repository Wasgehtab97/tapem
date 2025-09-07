class PublicProfile {
  PublicProfile({
    required this.uid,
    required this.username,
    this.usernameLower,
    this.avatarUrl,
    this.primaryGymCode,
    this.avatarKey,
  });

  final String uid;
  final String username;
  final String? usernameLower;
  final String? avatarUrl;
  final String? primaryGymCode;
  final String? avatarKey;

  String get computedUsernameLower =>
      usernameLower ?? username.toLowerCase();

  factory PublicProfile.fromMap(String id, Map<String, dynamic> data) {
    return PublicProfile(
      uid: id,
      username: data['username'] as String? ?? '',
      usernameLower: data['usernameLower'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      primaryGymCode: data['primaryGymCode'] as String?,
      avatarKey: data['avatarKey'] as String? ?? 'default',
    );
  }
}
