// lib/main.dart
// ignore_for_file: avoid_print, use_super_parameters

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app_router.dart';
import 'core/theme/theme_loader.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/gym_provider.dart';
import 'core/providers/device_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/exercise_provider.dart';
import 'core/providers/report_provider.dart';

import 'features/nfc/data/nfc_service.dart';
import 'features/nfc/domain/usecases/read_nfc_code.dart';
import 'features/nfc/domain/usecases/write_nfc_tag.dart';
import 'features/nfc/widgets/global_nfc_listener.dart';

import 'features/device/data/sources/firestore_device_source.dart';
import 'features/device/data/repositories/device_repository_impl.dart';
import 'features/device/domain/repositories/device_repository.dart';
import 'features/device/domain/usecases/create_device_usecase.dart';
import 'features/device/domain/usecases/get_devices_for_gym.dart';
import 'features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'features/device/domain/usecases/delete_device_usecase.dart';

import 'features/device/data/sources/firestore_exercise_source.dart';
import 'features/device/data/repositories/exercise_repository_impl.dart';
import 'features/device/domain/repositories/exercise_repository.dart';
import 'features/device/domain/usecases/get_exercises_for_device.dart';
import 'features/device/domain/usecases/create_exercise_usecase.dart';
import 'features/device/domain/usecases/delete_exercise_usecase.dart';

import 'features/report/data/repositories/report_repository_impl.dart';
import 'features/report/domain/usecases/get_device_usage_stats.dart';
import 'features/report/domain/usecases/get_all_log_timestamps.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

/// Global navigator key for NFC navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: '.env.dev').catchError((_) {});

  // Firebase init
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // Disable reCAPTCHA for tests
  fb_auth.FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  // Date formatting
  await initializeDateFormatting();

  // Offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const AppEntry());
}

class AppEntry extends StatelessWidget {
  const AppEntry({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare report use cases
    final reportRepo = ReportRepositoryImpl();
    final usageUC = GetDeviceUsageStats(reportRepo);
    final logsUC = GetAllLogTimestamps(reportRepo);

    return MultiProvider(
      providers: [
        // NFC
        Provider<NfcService>(create: (_) => NfcService()),
        Provider<ReadNfcCode>(create: (c) => ReadNfcCode(c.read<NfcService>())),
        Provider<WriteNfcTagUseCase>(create: (_) => WriteNfcTagUseCase()),

        // Device
        Provider<DeviceRepository>(
          create: (_) => DeviceRepositoryImpl(FirestoreDeviceSource()),
        ),
        Provider<CreateDeviceUseCase>(
          create: (c) => CreateDeviceUseCase(c.read<DeviceRepository>()),
        ),
        Provider<GetDevicesForGym>(
          create: (c) => GetDevicesForGym(c.read<DeviceRepository>()),
        ),
        Provider<GetDeviceByNfcCode>(
          create: (c) => GetDeviceByNfcCode(c.read<DeviceRepository>()),
        ),
        Provider<DeleteDeviceUseCase>(
          create: (c) => DeleteDeviceUseCase(c.read<DeviceRepository>()),
        ),

        // Exercise
        Provider<ExerciseRepository>(
          create: (_) => ExerciseRepositoryImpl(FirestoreExerciseSource()),
        ),
        Provider<GetExercisesForDevice>(
          create: (c) => GetExercisesForDevice(c.read<ExerciseRepository>()),
        ),
        Provider<CreateExerciseUseCase>(
          create: (c) => CreateExerciseUseCase(c.read<ExerciseRepository>()),
        ),
        Provider<DeleteExerciseUseCase>(
          create: (c) => DeleteExerciseUseCase(c.read<ExerciseRepository>()),
        ),

        // App state
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ThemeLoader>(
          create: (_) => ThemeLoader()..loadDefault(),
          update: (ctx, auth, prev) {
            final loader = prev ?? (ThemeLoader()..loadDefault());
            loader.loadGymTheme(auth.gymCode ?? '');
            return loader;
          },
        ),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create:
              (c) => ExerciseProvider(
                getEx: c.read<GetExercisesForDevice>(),
                createEx: c.read<CreateExerciseUseCase>(),
                deleteEx: c.read<DeleteExerciseUseCase>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (_) => ReportProvider(
                getUsageStats: usageUC,
                getLogTimestamps: logsUC,
              ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeLoader>().theme;
    final locale = context.watch<AppProvider>().locale;

    final child =
        Platform.isAndroid
            ? GlobalNfcListener(child: _buildApp(theme, locale))
            : _buildApp(theme, locale);

    return child;
  }

  MaterialApp _buildApp(ThemeData theme, Locale? locale) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: dotenv.env['APP_NAME'] ?? 'Tap’em',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute:
          (_) => MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}
