/// Represents a sticker that can be sent in chat.
class Sticker {
  const Sticker({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isPremium = false,
  });

  final String id;
  final String name;
  final String imageUrl;
  final bool isPremium;

  factory Sticker.fromJson(Map<String, dynamic> json) {
    return Sticker(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'isPremium': isPremium,
    };
  }
}
