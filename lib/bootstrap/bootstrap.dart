// lib/bootstrap/bootstrap.dart

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/avatars/domain/services/avatar_catalog.dart';
import '../features/report/data/repositories/report_repository_impl.dart';
import '../features/report/domain/usecases/get_all_log_timestamps.dart';
import '../features/report/domain/usecases/get_device_usage_stats.dart';
import '../core/database/database_service.dart';
import '../core/sync/sync_service.dart';
import 'firebase.dart';
import 'providers.dart';


class BootstrapResult {
  const BootstrapResult({
    required this.sharedPreferences,
    required this.getUsageStats,
    required this.getLogTimestamps,
    required this.databaseService,
    required this.syncService,
  });

  final SharedPreferences sharedPreferences;
  final GetDeviceUsageStats getUsageStats;
  final GetAllLogTimestamps getLogTimestamps;
  final DatabaseService databaseService;
  final SyncService syncService;

  List<Override> toOverrides() {
    return [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      getDeviceUsageStatsProvider.overrideWithValue(getUsageStats),
      getAllLogTimestampsProvider.overrideWithValue(getLogTimestamps),
      databaseServiceProvider.overrideWithValue(databaseService),
      syncServiceProvider.overrideWithValue(syncService),
    ];
  }
}


Future<BootstrapResult> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env.dev').catchError((_) {});
  await ensureFirebaseInitialized();
  assert(() {
    debugPrint('[Firebase] projectId=' + Firebase.app().options.projectId);
    return true;
  }());
  await initializeAppCheck();
  configureFirestorePersistence();
  configurePhoneAuthForDebug();

  if (kEnablePush) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await initializePushMessaging();
  }

  await initializeDateFormatting();
  await AvatarCatalog.instance.warmUp(bundle: rootBundle);
  assert(() {
    if (!AvatarCatalog.instance.warmed ||
        !AvatarCatalog.instance.manifestHasPrefix) {
      debugPrint(
          '[AvatarCatalog] manifest_missing_prefix assets/avatars/ – check pubspec.yaml and assets/avatars/');
    }
    return true;
  }());

  final reportRepo = ReportRepositoryImpl();
  final usageUC = GetDeviceUsageStats(reportRepo);
  final logsUC = GetAllLogTimestamps(reportRepo);
  final sharedPrefs = await SharedPreferences.getInstance();

  final databaseService = DatabaseService();
  await databaseService.init();

  final syncService = SyncService(databaseService);
  syncService.init();

  return BootstrapResult(
    sharedPreferences: sharedPrefs,
    getUsageStats: usageUC,
    getLogTimestamps: logsUC,
    databaseService: databaseService,
    syncService: syncService,
  );
}

