import 'package:cloud_firestore/cloud_firestore.dart';

class AvatarUnlock {
  AvatarUnlock({required this.type, this.params});

  final String type; // xp|challenge|event|manual
  final Map<String, dynamic>? params;

  factory AvatarUnlock.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return AvatarUnlock(type: 'manual');
    }
    return AvatarUnlock(
      type: data['type'] as String? ?? 'manual',
      params: data['params'] as Map<String, dynamic>?,
    );
  }
}

class AvatarCatalogItem {
  AvatarCatalogItem({
    required this.id,
    required this.name,
    this.description,
    this.assetStoragePath,
    this.assetUrl,
    required this.isActive,
    this.tier,
    required this.unlock,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  final String id;
  final String name;
  final String? description;
  final String? assetStoragePath;
  final String? assetUrl;
  final bool isActive;
  final String? tier; // common|rare|legendary
  final AvatarUnlock unlock;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  factory AvatarCatalogItem.fromMap(String id, Map<String, dynamic> data) {
    return AvatarCatalogItem(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      assetStoragePath: data['assetStoragePath'] as String?,
      assetUrl: data['assetUrl'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      tier: data['tier'] as String?,
      unlock: AvatarUnlock.fromMap(data['unlock'] as Map<String, dynamic>?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
      updatedBy: data['updatedBy'] as String?,
    );
  }
}
