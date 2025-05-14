// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'affiliate_offer_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AffiliateOfferDto _$AffiliateOfferDtoFromJson(Map<String, dynamic> json) =>
    AffiliateOfferDto(
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      affiliateUrl: json['affiliate_url'] as String,
    );

Map<String, dynamic> _$AffiliateOfferDtoToJson(AffiliateOfferDto instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'affiliate_url': instance.affiliateUrl,
    };
