import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/deals/domain/models/deal.dart';

void main() {
  group('Deal', () {
    test('fromMap trims text fields and normalizes urls', () {
      final deal = Deal.fromMap('deal_1', {
        'title': '  Summer Deal  ',
        'description': '  Big discount  ',
        'partnerName': '  OACE  ',
        'partnerLogoUrl': ' https://oace.de/logo black.png ',
        'imageUrl': ' https://oace.de/banner image.png ',
        'code': '  SAVE20 ',
        'link': ' https://shop.example.com/deal 1 ',
        'category': '  Supplements ',
        'isActive': true,
        'priority': 4,
        'createdAt': Timestamp.fromDate(DateTime.utc(2025, 1, 1)),
        'clickCount': 2,
      });

      expect(deal.id, 'deal_1');
      expect(deal.title, 'Summer Deal');
      expect(deal.description, 'Big discount');
      expect(deal.partnerName, 'OACE');
      expect(deal.partnerLogoUrl, 'https://oace.de/logo%20black.png');
      expect(deal.imageUrl, 'https://oace.de/banner%20image.png');
      expect(deal.code, 'SAVE20');
      expect(deal.link, 'https://shop.example.com/deal%201');
      expect(deal.category, 'Supplements');
      expect(deal.isActive, isTrue);
      expect(deal.priority, 4);
      expect(deal.clickCount, 2);
    });

    test('toMap writes trimmed text and normalized urls', () {
      final deal = Deal(
        id: 'deal_2',
        title: '  Winter Deal  ',
        description: '  Description  ',
        partnerName: '  Partner  ',
        partnerLogoUrl: ' https://example.com/logo black.png ',
        imageUrl: ' https://example.com/banner image.png ',
        code: '  CODE10 ',
        link: ' https://example.com/shop page ',
        category: '  Category  ',
        isActive: true,
        priority: 1,
        createdAt: DateTime.utc(2025, 1, 1),
      );

      final map = deal.toMap();

      expect(map['title'], 'Winter Deal');
      expect(map['description'], 'Description');
      expect(map['partnerName'], 'Partner');
      expect(map['partnerLogoUrl'], 'https://example.com/logo%20black.png');
      expect(map['imageUrl'], 'https://example.com/banner%20image.png');
      expect(map['code'], 'CODE10');
      expect(map['link'], 'https://example.com/shop%20page');
      expect(map['category'], 'Category');
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}
