// lib/main.dart
// ignore_for_file: avoid_print, use_super_parameters

import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app_router.dart';
import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/core/providers/app_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/all_exercises_provider.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/features/survey/survey_provider.dart';
import 'features/gym/data/sources/firestore_gym_source.dart';

import 'features/nfc/data/nfc_service.dart';
import 'features/nfc/domain/usecases/read_nfc_code.dart';
import 'features/nfc/domain/usecases/write_nfc_tag.dart';
import 'features/nfc/widgets/global_nfc_listener.dart';
import 'features/auth/presentation/widgets/dynamic_link_listener.dart';

import 'features/device/data/sources/firestore_device_source.dart';
import 'features/device/data/repositories/device_repository_impl.dart';
import 'features/device/domain/repositories/device_repository.dart';
import 'features/device/domain/usecases/create_device_usecase.dart';
import 'features/device/domain/usecases/get_devices_for_gym.dart';
import 'features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'features/device/domain/usecases/delete_device_usecase.dart';
import 'features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'features/device/domain/usecases/set_device_muscle_groups_usecase.dart';

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

import 'core/feature_flags.dart';

/// Global navigator key for NFC navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: '.env.dev').catchError((_) {});

  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  fb_auth.FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  await initializeDateFormatting();

  final flags = await FeatureFlags.init(app);
  runApp(AppEntry(featureFlags: flags));
}

class AppEntry extends StatelessWidget {
  final FeatureFlags featureFlags;
  const AppEntry({Key? key, required this.featureFlags}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare report use cases
    final reportRepo = ReportRepositoryImpl();
    final usageUC = GetDeviceUsageStats(reportRepo);
    final logsUC = GetAllLogTimestamps(reportRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FeatureFlags>.value(value: featureFlags),
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
        Provider<UpdateDeviceMuscleGroupsUseCase>(
          create:
              (c) =>
                  UpdateDeviceMuscleGroupsUseCase(c.read<DeviceRepository>()),
        ),
        Provider<SetDeviceMuscleGroupsUseCase>(
          create:
              (c) => SetDeviceMuscleGroupsUseCase(c.read<DeviceRepository>()),
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
        ChangeNotifierProxyProvider<AuthProvider, BrandingProvider>(
          create: (_) => BrandingProvider(
            source: FirestoreGymSource(firestore: FirebaseFirestore.instance),
          ),
          update: (_, auth, prov) {
            final p = prov ?? BrandingProvider(
              source: FirestoreGymSource(
                firestore: FirebaseFirestore.instance,
              ),
            );
            p.loadBrandingWithGym(auth.gymCode);
            return p;
          },
        ),
        ChangeNotifierProxyProvider<BrandingProvider, ThemeLoader>(
          create: (_) => ThemeLoader()..loadDefault(),
          update: (_, branding, loader) {
            final l = loader ?? (ThemeLoader()..loadDefault());
            l.applyBranding(branding.branding);
            return l;
          },
        ),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MuscleGroupProvider()),
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
              (c) =>
                  AllExercisesProvider(getEx: c.read<GetExercisesForDevice>()),
        ),
        ChangeNotifierProvider(
          create:
              (_) => ReportProvider(
                getUsageStats: usageUC,
                getLogTimestamps: logsUC,
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => SurveyProvider(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedbackProvider(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        ChangeNotifierProvider(create: (_) => RankProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => XpProvider()),
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

    Widget app = _buildApp(theme, locale);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      app = GlobalNfcListener(child: app);
    }
    return DynamicLinkListener(child: app);
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
