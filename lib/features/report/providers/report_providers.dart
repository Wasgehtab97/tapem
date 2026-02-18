// lib/features/report/providers/report_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/gym_scoped_resettable.dart';
import '../../../core/providers/report_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../features/report/data/training_day_repository.dart';
import '../../../features/report/domain/usecases/get_all_log_timestamps.dart';
import '../../../features/report/domain/usecases/get_device_usage_stats.dart';

final getDeviceUsageStatsProvider = Provider<GetDeviceUsageStats>((ref) {
  throw UnimplementedError('GetDeviceUsageStats not initialized');
});

final getAllLogTimestampsProvider = Provider<GetAllLogTimestamps>((ref) {
  throw UnimplementedError('GetAllLogTimestamps not initialized');
});

final trainingDayRepositoryProvider = Provider<TrainingDayRepository>((ref) {
  return TrainingDayRepository();
});

final reportProvider = ChangeNotifierProvider<ReportProvider>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final usage = ref.watch(getDeviceUsageStatsProvider);
  final logs = ref.watch(getAllLogTimestampsProvider);
  final provider = ReportProvider(
    getUsageStats: usage,
    getLogTimestamps: logs,
    preferences: prefs,
  );
  provider.registerGymScopedResettable(
    ref.read(gymScopedStateControllerProvider),
  );
  return provider;
});
