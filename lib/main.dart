// lib/main.dart
// ignore_for_file: avoid_print, use_super_parameters

import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb, kReleaseMode;

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:tapem/features/friends/data/friends_api.dart';
import 'package:tapem/features/friends/data/friends_source.dart';
import 'package:tapem/features/friends/data/public_profile_source.dart';
import 'package:tapem/features/friends/data/public_calendar_source.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/features/friends/providers/friend_calendar_provider.dart';
import 'features/gym/data/sources/firestore_gym_source.dart';
import 'ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'core/drafts/session_draft_repository_impl.dart';
import 'services/membership_service.dart';

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
import 'features/device/domain/usecases/update_exercise_usecase.dart';
import 'features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';

import 'features/report/data/repositories/report_repository_impl.dart';
import 'features/report/domain/usecases/get_device_usage_stats.dart';
import 'features/report/domain/usecases/get_all_log_timestamps.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

/// Global navigator key for NFC navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Falls der Prozess im Hintergrund startet, Firebase erneut initialisieren.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _initMessaging() async {
  final messaging = FirebaseMessaging.instance;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }
  final token = await messaging.getToken();
  if (token != null) {
    await _registerToken(token);
  }
  FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
}

Future<void> _registerToken(String token) async {
  final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  try {
    await FirebaseFunctions.instance
        .httpsCallable('registerPushToken')
        .call({'token': token, 'platform': platform});
  } catch (_) {}
}

void _handleMessage(RemoteMessage message) {
  final action = message.data['action'];
  if (action == 'open_requests') {
    navigatorKey.currentState?.pushNamed(AppRouter.friendsHome);
  } else if (action == 'open_friend') {
    final uid = message.data['uid'];
    navigatorKey.currentState
        ?.pushNamed(AppRouter.friendDetail, arguments: uid);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env laden (optional, fällt sonst sauber zurück)
  await dotenv.load(fileName: '.env.dev').catchError((_) {});

  // Firebase init (einheitlich für alle Konfigurationen)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // App Check (iOS: DeviceCheck für TestFlight/Prod)
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.deviceCheck,
    // debugProvider: kReleaseMode ? false : true, // optional: Debug im Simulator/Debug
  );

  // Firestore Offline-Persistenz
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Optional: Phone-Auth Test-Setting NUR in Debug
  assert(() {
    fb_auth.FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
    return true;
  }());

  // Background-Messaging Handler registrieren (sicher, auch wenn ungenutzt)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _initMessaging();

  // Date formatting
  await initializeDateFormatting();

  // Prepare report use cases
  final reportRepo = ReportRepositoryImpl();
  final usageUC = GetDeviceUsageStats(reportRepo);
  final logsUC = GetAllLogTimestamps(reportRepo);

  runApp(
    MultiProvider(
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
        Provider<UpdateExerciseUseCase>(
          create: (c) => UpdateExerciseUseCase(c.read<ExerciseRepository>()),
        ),
        Provider<UpdateExerciseMuscleGroupsUseCase>(
          create: (c) =>
              UpdateExerciseMuscleGroupsUseCase(c.read<ExerciseRepository>()),
        ),

        // App state
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Friends feature
        Provider<FriendsApi>(create: (_) => FriendsApi()),
        Provider<FriendsSource>(
          create: (_) => FriendsSource(FirebaseFirestore.instance),
        ),
        Provider<PublicProfileSource>(
          create: (_) => PublicProfileSource(FirebaseFirestore.instance),
        ),
        Provider<PublicCalendarSource>(
          create: (_) => PublicCalendarSource(FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(
          create: (c) => FriendsProvider(
            c.read<FriendsSource>(),
            c.read<FriendsApi>(),
            c.read<PublicProfileSource>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => FriendCalendarProvider(
            c.read<PublicCalendarSource>(),
          ),
        ),

        // Numeric keypad
        ChangeNotifierProvider<OverlayNumericKeypadController>(
          create: (_) => OverlayNumericKeypadController(),
        ),

        Provider<MembershipService>(
          create: (_) => FirestoreMembershipService(),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          MembershipService,
          BrandingProvider
        >(
          create: (c) => BrandingProvider(
            source: FirestoreGymSource(firestore: FirebaseFirestore.instance),
            membership: c.read<MembershipService>(),
          ),
          update: (_, auth, m, prov) {
            final p =
                prov ??
                BrandingProvider(
                  source: FirestoreGymSource(
                    firestore: FirebaseFirestore.instance,
                  ),
                  membership: m,
                );
            p.loadBrandingWithGym(auth.gymCode, auth.userId);
            return p;
          },
        ),
        ChangeNotifierProxyProvider<BrandingProvider, ThemeLoader>(
          create: (_) => ThemeLoader()..loadDefault(),
          update: (_, branding, loader) {
            final l = loader ?? (ThemeLoader()..loadDefault());
            l.applyBranding(branding.gymId, branding.branding);
            return l;
          },
        ),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(
          create: (c) => DeviceProvider(
            firestore: FirebaseFirestore.instance,
            draftRepo: SessionDraftRepositoryImpl(),
            membership: c.read<MembershipService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (c) =>
              MuscleGroupProvider(membership: c.read<MembershipService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => ExerciseProvider(
            getEx: c.read<GetExercisesForDevice>(),
            createEx: c.read<CreateExerciseUseCase>(),
            deleteEx: c.read<DeleteExerciseUseCase>(),
            updateEx: c.read<UpdateExerciseUseCase>(),
            updateMuscles: c.read<UpdateExerciseMuscleGroupsUseCase>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) =>
              AllExercisesProvider(getEx: c.read<GetExercisesForDevice>()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ReportProvider(getUsageStats: usageUC, getLogTimestamps: logsUC),
        ),
        ChangeNotifierProvider(
          create: (_) => SurveyProvider(firestore: FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FeedbackProvider(firestore: FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(create: (_) => RankProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => XpProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeLoader>().theme;
    final locale = context.watch<AppProvider>().locale;
    final keypad = context.read<OverlayNumericKeypadController>();

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
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const SplashScreen()),
      builder: (context, child) {
        Widget app = child!;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          app = GlobalNfcListener(child: app);
        }
        app = DynamicLinkListener(child: app);
        return OverlayNumericKeypadHost(
          controller: keypad,
          outsideTapMode: OutsideTapMode.closeAfterTap,
          child: app,
        );
      },
    );
  }
}
