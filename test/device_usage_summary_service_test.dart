import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// ignore: implementation_imports
import 'package:hive/src/hive_impl.dart';
import 'package:tapem/core/services/device_usage_summary_service.dart';

void main() {
  group('DeviceUsageSummaryService caching', () {
    late FakeFirebaseFirestore firestore;
    late HiveInterface hive;
    late Directory tempDir;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      tempDir = await Directory.systemTemp.createTemp('device_usage_test');
      final hiveImpl = HiveImpl();
      hiveImpl.init(tempDir.path);
      hive = hiveImpl;
    });

    tearDown(() async {
      await hive.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('reads summaries once and serves cached responses', () async {
      const gymId = 'gym-42';
      await _seedDeviceSummaries(firestore: firestore, gymId: gymId);

      var readCount = 0;
      final coldService = DeviceUsageSummaryService(
        firestore: firestore,
        ttl: Duration.zero,
        onRead: () => readCount++,
        hive: hive,
      );

      final initial = await coldService.loadSummaries(gymId);
      expect(initial.fromCache, isFalse);
      expect(initial.entries, isNotEmpty);
      expect(readCount, equals(1));

      final warmService = DeviceUsageSummaryService(
        firestore: firestore,
        ttl: const Duration(hours: 12),
        onRead: () => readCount++,
        hive: hive,
      );

      final cached = await warmService.loadSummaries(gymId);
      expect(cached.fromCache, isTrue);
      expect(cached.entries.length, equals(initial.entries.length));
      expect(readCount, equals(1), reason: 'Hive cache avoids follow-up reads');

      final recentDates = await warmService.fetchRecentActivityDates(gymId);
      expect(recentDates, equals(<DateTime>[
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 3),
      ]));
    });
  });
}

Future<void> _seedDeviceSummaries({
  required FakeFirebaseFirestore firestore,
  required String gymId,
}) async {
  final devices = firestore.collection('deviceUsageSummary').doc(gymId).collection('devices');
  for (var i = 0; i < 12; i++) {
    final recent = <Timestamp>[
      Timestamp.fromDate(DateTime(2024, 1, 1 + (i % 3))),
      if (i.isEven) Timestamp.fromDate(DateTime(2024, 1, 2)),
    ];
    await devices.doc('device_$i').set({
      'name': 'Device $i',
      'description': 'Desc $i',
      'sessionCount': i + 1,
      'rollingSessions': {
        'last7Days': 1,
        'last30Days': 2,
        'last90Days': 3,
        'last365Days': 4,
        'all': i + 1,
      },
      'lastActive': Timestamp.fromDate(DateTime(2024, 1, 3)),
      'recentDates': recent,
    });
  }
}
