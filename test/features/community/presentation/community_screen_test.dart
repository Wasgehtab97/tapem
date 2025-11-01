import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:tapem/features/community/data/firestore_community_stats_source.dart';
import 'package:tapem/features/community/domain/services/community_stats_service.dart';
import 'package:tapem/features/community/presentation/providers/community_providers.dart';
import 'package:tapem/features/community/presentation/screens/community_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommunityScreen', () {
    late FakeFirebaseFirestore firestore;
    late CommunityStatsService service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      final statsCol = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('stats_daily');
      await statsCol.doc('2024-10-28').set({
        'date': DateTime.utc(2024, 10, 28),
        'repsTotal': 20,
        'volumeTotal': 200,
        'trainingSessions': 1,
      });
      await statsCol.doc('2024-10-30').set({
        'date': DateTime.utc(2024, 10, 30),
        'repsTotal': 40,
        'volumeTotal': 500,
        'trainingSessions': 2,
      });
      await statsCol.doc('2024-11-01').set({
        'date': DateTime.utc(2024, 11, 1),
        'repsTotal': 42,
        'volumeTotal': 1000,
        'trainingSessions': 2,
      });

      final feedCol = firestore
          .collection('gyms')
          .doc('gym1')
          .collection('feed_events');
      await feedCol.doc('evt1').set({
        'type': 'session_summary',
        'createdAt': DateTime.utc(2024, 11, 1, 8, 30),
        'userId': 'u1',
        'username': 'Alice',
        'dayKey': '2024-11-01',
        'reps': 30,
        'volume': 250,
      });

      final source = FirestoreCommunityStatsSource(firestore: firestore);
      service = CommunityStatsService(
        source,
        clock: () => DateTime(2024, 11, 1, 12),
      );
    });

    testWidgets('renders KPIs and feed entries', (tester) async {
      Intl.defaultLocale = 'en';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityStatsServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CommunityScreen(gymId: 'gym1'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Total reps'), findsOneWidget);
      expect(find.textContaining('42'), findsWidgets);
      expect(find.textContaining('1,000'), findsWidgets);
      expect(find.textContaining('Alice'), findsOneWidget);

      await tester.tap(find.text('Week'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('102'), findsWidgets);
      expect(find.textContaining('1,700'), findsWidgets);
    });
  });
}
