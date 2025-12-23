// lib/features/gym/domain/models/gym_config.dart
class GymConfig {
  final String id;
  final String code;
  final String name;
  final String? logoUrl;
  final String? primaryColor;
  final String? accentColor;
  final String? region;
  final String? status;

  GymConfig({
    required this.id,
    required this.code,
    required this.name,
    this.logoUrl,
    this.primaryColor,
    this.accentColor,
    this.region,
    this.status,
  });

  GymConfig.empty(this.id)
      : 
        code = '',
        name = id,
        logoUrl = null,
        primaryColor = null,
        accentColor = null,
        region = null,
        status = null;

  factory GymConfig.fromMap(String id, Map<String, dynamic> data) {
    return GymConfig(
      id: id,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      primaryColor: data['primaryColor'] as String?,
      accentColor: data['accentColor'] as String?,
      region: data['region'] as String?,
      status: data['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (primaryColor != null) 'primaryColor': primaryColor,
      if (accentColor != null) 'accentColor': accentColor,
      if (region != null) 'region': region,
      if (status != null) 'status': status,
    };
  }
}
