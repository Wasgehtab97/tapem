// lib/main.dart
// ignore_for_file: avoid_print, use_super_parameters

import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb, kDebugMode;

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'bootstrap/firebase_bootstrap.dart';
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
import 'features/report/data/sources/firestore_report_source.dart';
import 'features/report/domain/usecases/get_device_usage_stats.dart';
import 'features/report/domain/usecases/get_all_log_timestamps.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/sources/firestore_auth_source.dart';
import 'features/gym/data/repositories/gym_repository_impl.dart';
import 'features/challenges/data/repositories/challenge_repository_impl.dart';
import 'features/challenges/data/sources/firestore_challenge_source.dart';
import 'features/xp/data/repositories/xp_repository_impl.dart';
import 'features/xp/data/sources/firestore_xp_source.dart';
import 'features/rank/data/repositories/rank_repository_impl.dart';
import 'features/rank/data/sources/firestore_rank_source.dart';
import 'features/training_plan/data/repositories/training_plan_repository_impl.dart';
import 'features/training_plan/data/sources/firestore_training_plan_source.dart';
import 'features/history/data/repositories/history_repository_impl.dart';
import 'features/history/data/sources/firestore_history_source.dart';
import 'features/history/domain/usecases/get_history_for_device.dart';
import 'features/muscle_group/data/repositories/muscle_group_repository_impl.dart';
import 'features/muscle_group/data/sources/firestore_muscle_group_source.dart';
import 'features/muscle_group/domain/usecases/get_muscle_groups_for_gym.dart';
import 'features/muscle_group/domain/usecases/save_muscle_group.dart';
import 'features/muscle_group/domain/usecases/delete_muscle_group.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

import 'core/feature_flags.dart';

/// Global navigator key for NFC navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: '.env.dev').catchError((_) {});

  final fb = await firebaseBootstrap();

  await initializeDateFormatting();

  final flags = await FeatureFlags.init(fb.remoteConfig);
  runApp(AppEntry(
    featureFlags: flags,
    firebase: fb,
  ));
}

class AppEntry extends StatelessWidget {
  final FeatureFlags featureFlags;
  final FirebaseBootstrap firebase;
  const AppEntry({
    Key? key,
    required this.featureFlags,
    required this.firebase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare report use cases
    final app = firebase.app;
    final firestore = firebase.firestore;
    final auth = firebase.auth;
    final rc = firebase.remoteConfig;
    final functions = firebase.functions;

    final reportRepo = ReportRepositoryImpl(FirestoreReportSource(firestore));
    final usageUC = GetDeviceUsageStats(reportRepo);
    final logsUC = GetAllLogTimestamps(reportRepo);

    return MultiProvider(
      providers: [
        Provider<FirebaseApp>.value(value: app),
        Provider<FirebaseFirestore>.value(value: firestore),
        Provider<fb_auth.FirebaseAuth>.value(value: auth),
        Provider<FirebaseRemoteConfig>.value(value: rc),
        if (functions != null)
          Provider<FirebaseFunctions>.value(value: functions),
        ChangeNotifierProvider<FeatureFlags>.value(value: featureFlags),

        // NFC
        Provider<NfcService>(create: (_) => NfcService()),
        Provider<ReadNfcCode>(create: (c) => ReadNfcCode(c.read<NfcService>())),
        Provider<WriteNfcTagUseCase>(create: (_) => WriteNfcTagUseCase()),

        // Device
        Provider<DeviceRepository>(
          create: (_) => DeviceRepositoryImpl(
            FirestoreDeviceSource(firestore: firestore),
          ),
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
          create: (c) =>
              UpdateDeviceMuscleGroupsUseCase(c.read<DeviceRepository>()),
        ),
        Provider<SetDeviceMuscleGroupsUseCase>(
          create: (c) =>
              SetDeviceMuscleGroupsUseCase(c.read<DeviceRepository>()),
        ),

        // Exercise
        Provider<ExerciseRepository>(
          create: (_) => ExerciseRepositoryImpl(
            FirestoreExerciseSource(firestore: firestore),
          ),
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
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            repo: AuthRepositoryImpl(
              FirestoreAuthSource(auth: auth, firestore: firestore),
            ),
            auth: auth,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BrandingProvider>(
          create: (_) => BrandingProvider(
            source: FirestoreGymSource(firestore: firestore),
          ),
          update: (_, authProv, prov) {
            final p = prov ??
                BrandingProvider(
                  source: FirestoreGymSource(firestore: firestore),
                );
            p.loadBrandingWithGym(authProv.gymCode);
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
        ChangeNotifierProvider(
          create: (_) => GymProvider(
            gymRepo: GymRepositoryImpl(
              FirestoreGymSource(firestore: firestore),
            ),
            deviceRepo: DeviceRepositoryImpl(
              FirestoreDeviceSource(firestore: firestore),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(
            firestore: firestore,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TrainingPlanProvider(
            repo: TrainingPlanRepositoryImpl(
              FirestoreTrainingPlanSource(firestore: firestore),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            getHistory: GetHistoryForDevice(
              HistoryRepositoryImpl(
                FirestoreHistorySource(firestore: firestore),
              ),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            getHistory: GetHistoryForDevice(
              HistoryRepositoryImpl(
                FirestoreHistorySource(firestore: firestore),
              ),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MuscleGroupProvider(
            getGroups: GetMuscleGroupsForGym(
              MuscleGroupRepositoryImpl(
                FirestoreMuscleGroupSource(firestore: firestore),
              ),
            ),
            saveGroup: SaveMuscleGroup(
              MuscleGroupRepositoryImpl(
                FirestoreMuscleGroupSource(firestore: firestore),
              ),
            ),
            deleteGroup: DeleteMuscleGroup(
              MuscleGroupRepositoryImpl(
                FirestoreMuscleGroupSource(firestore: firestore),
              ),
            ),
            getHistory: GetHistoryForDevice(
              HistoryRepositoryImpl(
                FirestoreHistorySource(firestore: firestore),
              ),
            ),
            updateDeviceGroups: UpdateDeviceMuscleGroupsUseCase(
              DeviceRepositoryImpl(
                FirestoreDeviceSource(firestore: firestore),
              ),
            ),
            setDeviceGroups: SetDeviceMuscleGroupsUseCase(
              DeviceRepositoryImpl(
                FirestoreDeviceSource(firestore: firestore),
              ),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => ExerciseProvider(
            getEx: c.read<GetExercisesForDevice>(),
            createEx: c.read<CreateExerciseUseCase>(),
            deleteEx: c.read<DeleteExerciseUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) =>
              AllExercisesProvider(getEx: c.read<GetExercisesForDevice>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(
            getUsageStats: usageUC,
            getLogTimestamps: logsUC,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SurveyProvider(firestore: firestore),
        ),
        ChangeNotifierProvider(
          create: (_) => FeedbackProvider(firestore: firestore),
        ),
        ChangeNotifierProvider(
          create: (_) => RankProvider(
            repository: RankRepositoryImpl(
              FirestoreRankSource(firestore: firestore),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChallengeProvider(
            repo: ChallengeRepositoryImpl(
              FirestoreChallengeSource(firestore: firestore),
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => XpProvider(
            repo: XpRepositoryImpl(
              FirestoreXpSource(firestore: firestore),
            ),
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
