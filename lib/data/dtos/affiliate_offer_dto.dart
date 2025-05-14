// lib/data/dtos/affiliate_offer_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'affiliate_offer_dto.g.dart';

@JsonSerializable()
class AffiliateOfferDto {
  final String title;
  final String description;

  @JsonKey(name: 'image_url')
  final String imageUrl;

  @JsonKey(name: 'affiliate_url')
  final String affiliateUrl;

  AffiliateOfferDto({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.affiliateUrl,
  });

  factory AffiliateOfferDto.fromJson(Map<String, dynamic> json) =>
      _$AffiliateOfferDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AffiliateOfferDtoToJson(this);
}
