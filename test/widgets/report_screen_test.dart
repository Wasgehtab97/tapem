import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/core/services/device_usage_summary_service.dart';
import 'package:tapem/core/services/training_summary_service.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/features/report/domain/models/device_usage_range.dart';
import 'package:tapem/features/report/presentation/screens/report_screen_new.dart';
import 'package:tapem/features/report/presentation/widgets/device_usage_chart.dart';

class FakeDeviceUsageSummaryService extends DeviceUsageSummaryService {
  FakeDeviceUsageSummaryService({required this.entries})
      : super(firestore: FakeFirebaseFirestore());

  final List<DeviceUsageSummaryEntry> entries;

  @override
  Future<DeviceUsageSummaryState> loadSummaries(
    String gymId, {
    bool forceRefresh = false,
  }) async {
    return DeviceUsageSummaryState(entries: entries, fromCache: false);
  }

  @override
  Future<List<DateTime>> fetchRecentActivityDates(
    String gymId, {
    bool forceRefresh = false,
  }) async {
    final uniqueDays = <DateTime>{};
    for (final entry in entries) {
      for (final date in entry.recentDates) {
        uniqueDays.add(DateTime(date.year, date.month, date.day));
      }
    }
    final list = uniqueDays.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }
}

class FakeTrainingSummaryService extends TrainingSummaryService {
  FakeTrainingSummaryService({this.groupUsageCounts = const {}})
      : super(firestore: FakeFirebaseFirestore());

  final Map<String, int> groupUsageCounts;

  @override
  Future<Map<String, int>> fetchGroupUsageCounts({
    required String gymId,
    required String userId,
    bool forceRefresh = false,
  }) async {
    return groupUsageCounts;
  }
}

DeviceUsageSummaryEntry _makeEntry({
  String id = 'd1',
  String name = 'Device 1',
  String description = '',
  int totalSessions = 1,
  Map<String, int>? rangeCounts,
  List<DateTime>? recentDates,
}) {
  return DeviceUsageSummaryEntry(
    deviceId: id,
    name: name,
    description: description,
    totalSessions: totalSessions,
    rangeCounts: rangeCounts ??
        {
          DeviceUsageRange.last30Days.rangeKey: 1,
        },
    lastActive: recentDates?.isNotEmpty == true ? recentDates!.first : null,
    recentDates: recentDates ?? const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ReportScreenNew shows chart with fallback data', (tester) async {
    final reportProvider = ReportProvider(
      deviceSummaryService: FakeDeviceUsageSummaryService(
        entries: [
          _makeEntry(
            recentDates: const [DateTime(2024, 1, 1)],
          ),
        ],
      ),
      trainingSummaryService: FakeTrainingSummaryService(),
    );
    final feedbackProvider = FeedbackProvider(
      firestore: FakeFirebaseFirestore(),
      log: (_, [__]) {},
    );

    await reportProvider.loadReport('g1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReportProvider>.value(value: reportProvider),
          ChangeNotifierProvider<FeedbackProvider>.value(value: feedbackProvider),
        ],
        child: const MaterialApp(home: ReportScreenNew(gymId: 'g1')),
      ),
    );

    await tester.pump();

    expect(find.byType(DeviceUsageChart), findsOneWidget);
    final chart = tester.widget<DeviceUsageChart>(find.byType(DeviceUsageChart));
    expect(chart.usageData.isNotEmpty, true);
  });

  testWidgets('ReportScreenNew uses provided usage data', (tester) async {
    final reportProvider = ReportProvider(
      deviceSummaryService: FakeDeviceUsageSummaryService(
        entries: [
          _makeEntry(
            id: 'x',
            name: 'Device X',
            rangeCounts: {
              DeviceUsageRange.last30Days.rangeKey: 5,
            },
            totalSessions: 5,
          ),
        ],
      ),
      trainingSummaryService: FakeTrainingSummaryService(),
    );
    final feedbackProvider = FeedbackProvider(
      firestore: FakeFirebaseFirestore(),
      log: (_, [__]) {},
    );

    await reportProvider.loadReport('g1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReportProvider>.value(value: reportProvider),
          ChangeNotifierProvider<FeedbackProvider>.value(value: feedbackProvider),
        ],
        child: const MaterialApp(home: ReportScreenNew(gymId: 'g1')),
      ),
    );

    await tester.pump();

    final chart = tester.widget<DeviceUsageChart>(find.byType(DeviceUsageChart));
    expect(chart.usageData.first.sessions, 5);
    expect(chart.usageData.first.name, 'Device X');
  });
}
