import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/utils/remote_url_utils.dart';

class Deal {
  final String id;
  final String title;
  final String description;
  final String partnerName;
  final String partnerLogoUrl;
  final String imageUrl;
  final String code;
  final String link;
  final String category;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final DateTime? validUntil;
  final int clickCount;

  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.partnerName,
    required this.partnerLogoUrl,
    required this.imageUrl,
    required this.code,
    required this.link,
    required this.category,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    this.validUntil,
    this.clickCount = 0,
  });

  factory Deal.fromMap(String id, Map<String, dynamic> data) {
    return Deal(
      id: id,
      title: _readString(data, 'title'),
      description: _readString(data, 'description'),
      partnerName: _readString(data, 'partnerName'),
      partnerLogoUrl: normalizeRemoteUrl(_readString(data, 'partnerLogoUrl')),
      imageUrl: normalizeRemoteUrl(_readString(data, 'imageUrl')),
      code: _readString(data, 'code'),
      link: normalizeRemoteUrl(_readString(data, 'link')),
      category: _readString(data, 'category'),
      isActive: data['isActive'] as bool? ?? false,
      priority: (data['priority'] as num?)?.toInt() ?? 999,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      clickCount: (data['clickCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'partnerName': partnerName.trim(),
      'partnerLogoUrl': normalizeRemoteUrl(partnerLogoUrl),
      'imageUrl': normalizeRemoteUrl(imageUrl),
      'code': code.trim(),
      'link': normalizeRemoteUrl(link),
      'category': category.trim(),
      'isActive': isActive,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      if (validUntil != null) 'validUntil': Timestamp.fromDate(validUntil!),
      'clickCount': clickCount,
    };
  }

  Deal copyWith({
    String? id,
    String? title,
    String? description,
    String? partnerName,
    String? partnerLogoUrl,
    String? imageUrl,
    String? code,
    String? link,
    String? category,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
    DateTime? validUntil,
    int? clickCount,
  }) {
    return Deal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      partnerName: partnerName ?? this.partnerName,
      partnerLogoUrl: partnerLogoUrl ?? this.partnerLogoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      code: code ?? this.code,
      link: link ?? this.link,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
      clickCount: clickCount ?? this.clickCount,
    );
  }

  static String _readString(Map<String, dynamic> data, String key) {
    return (data[key] as String? ?? '').trim();
  }
}
