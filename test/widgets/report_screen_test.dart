import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:tapem/features/report/presentation/screens/report_screen_new.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/presentation/widgets/device_usage_chart.dart';
import '../firebase_test_utils.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.usage = const {}, this.times = const []});
  final Map<String, int> usage;
  final List<DateTime> times;
  @override
  Future<Map<String, int>> fetchUsageCountPerMachine(String gymId) async => usage;
  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId) async => times;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupFirebaseMocks();
  });

  testWidgets('ReportScreenNew shows chart with fallback data', (tester) async {
    final repo = FakeReportRepository();
    final reportProvider = ReportProvider(
      getUsageStats: GetDeviceUsageStats(repo),
      getLogTimestamps: GetAllLogTimestamps(repo),
    );
    final feedbackProvider = FeedbackProvider(firestore: FakeFirebaseFirestore());

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
}
