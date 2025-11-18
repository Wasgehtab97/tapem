// lib/bootstrap/bootstrap.dart

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/avatars/domain/services/avatar_catalog.dart';
import '../features/report/data/repositories/report_repository_impl.dart';
import '../features/report/domain/usecases/get_all_log_timestamps.dart';
import '../features/report/domain/usecases/get_device_usage_stats.dart';
import 'firebase.dart';
import 'providers.dart';

class BootstrapResult {
  const BootstrapResult({
    required this.sharedPreferences,
    required this.getUsageStats,
    required this.getLogTimestamps,
  });

  final SharedPreferences sharedPreferences;
  final GetDeviceUsageStats getUsageStats;
  final GetAllLogTimestamps getLogTimestamps;

  List<Override> toOverrides() {
    return [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      getDeviceUsageStatsProvider.overrideWithValue(getUsageStats),
      getAllLogTimestampsProvider.overrideWithValue(getLogTimestamps),
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

  return BootstrapResult(
    sharedPreferences: sharedPrefs,
    getUsageStats: usageUC,
    getLogTimestamps: logsUC,
  );
}
