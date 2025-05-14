/// Domain-Modell für ein Affiliate-Angebot.
class AffiliateOffer {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String affiliateUrl;

  const AffiliateOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.affiliateUrl,
  });

  factory AffiliateOffer.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AffiliateOffer(
      id: id,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['image_url'] as String,
      affiliateUrl: map['affiliate_url'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'affiliate_url': affiliateUrl,
      };

  @override
  String toString() =>
      'AffiliateOffer(id: $id, title: $title, affiliateUrl: $affiliateUrl)';
}
