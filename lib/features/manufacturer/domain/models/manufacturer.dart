import 'package:equatable/equatable.dart';

class Manufacturer extends Equatable {
  final String id;
  final String name;
  final String? logoUrl;
  final String? supportContact; // Gym-specific contact info
  final bool isGlobal; // true if from global list, false if custom gym-specific

  const Manufacturer({
    required this.id,
    required this.name,
    this.logoUrl,
    this.supportContact,
    this.isGlobal = true,
  });

  factory Manufacturer.fromJson(Map<String, dynamic> json) {
    return Manufacturer(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      supportContact: json['supportContact'] as String?,
      isGlobal: json['isGlobal'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (supportContact != null) 'supportContact': supportContact,
      'isGlobal': isGlobal,
    };
  }
  
  Manufacturer copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? supportContact,
    bool? isGlobal,
  }) {
    return Manufacturer(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      supportContact: supportContact ?? this.supportContact,
      isGlobal: isGlobal ?? this.isGlobal,
    );
  }

  @override
  List<Object?> get props => [id, name, logoUrl, supportContact, isGlobal];
}
