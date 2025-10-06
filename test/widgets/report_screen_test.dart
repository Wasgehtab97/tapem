import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/report/presentation/screens/report_screen_new.dart';
import 'package:tapem/features/report/presentation/widgets/device_usage_chart.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({
    this.usage = const [
      DeviceUsageStat(id: 'd1', name: 'Device 1', sessions: 1),
    ],
    this.times = const [],
  });
  final List<DeviceUsageStat> usage;
  final List<DateTime> times;
  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(
    String gymId, {
    DateTime? since,
  }) async => usage;
  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId) async => times;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ReportScreenNew shows chart with fallback data', (tester) async {
    final repo = FakeReportRepository();
    final reportProvider = ReportProvider(
      getUsageStats: GetDeviceUsageStats(repo),
      getLogTimestamps: GetAllLogTimestamps(repo),
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
    final repo = FakeReportRepository(
      usage: const [
        DeviceUsageStat(id: 'x', name: 'Device X', sessions: 5),
      ],
    );
    final reportProvider = ReportProvider(
      getUsageStats: GetDeviceUsageStats(repo),
      getLogTimestamps: GetAllLogTimestamps(repo),
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
