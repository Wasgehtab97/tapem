// lib/main.dart
// ignore_for_file: avoid_print, use_super_parameters

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'features/avatars/domain/services/avatar_catalog.dart';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tapem/core/providers/functions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/exercise_provider.dart';
import 'package:tapem/core/providers/all_exercises_provider.dart';
import 'package:tapem/core/providers/report_provider.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/core/providers/training_plan_provider.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/features/survey/survey_provider.dart';
import 'package:tapem/features/friends/data/friends_api.dart';
import 'package:tapem/features/friends/data/friends_source.dart';
import 'package:tapem/features/friends/data/user_search_source.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/features/friends/providers/friend_calendar_provider.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';
import 'package:tapem/features/creatine/data/creatine_repository.dart';
import 'package:tapem/features/creatine/providers/creatine_provider.dart';
import 'package:tapem/features/friends/providers/friend_search_provider.dart';
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

/// ─────────────────────────────────────────────────────────────
/// Globales Setup
/// ─────────────────────────────────────────────────────────────

/// Navigator-Key (z.B. für Deeplinks aus Push)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Push vorerst deaktiviert, da auf iOS-Simulator kein APNs-Token existiert.
/// Später auf `true` setzen, wenn APNs/FCM korrekt eingerichtet sind.
const bool kEnablePush = false;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Falls der Prozess im Hintergrund startet, Firebase erneut initialisieren.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  // Aktuell keine weitere Logik
}

Future<void> _initMessaging() async {
  // Safe init: niemals App-Absturz provozieren
  try {
    final messaging = FirebaseMessaging.instance;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Berechtigungen holen
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] permission denied → skip');
        return;
      }
      // Simulator hat kein APNs-Token → getToken() überspringen
      final apns = await messaging.getAPNSToken();
      if (apns == null) {
        debugPrint('[FCM] no APNs token (simulator?) → skip FCM token fetch');
        return;
      }
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _registerToken(
        t,
      ).catchError((e) => debugPrint('[FCM] onTokenRefresh error: $e'));
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  } catch (e, st) {
    debugPrint('[FCM] init failed: $e\n$st');
  }
}

Future<void> _registerToken(String token) async {
  final platform = defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';
  try {
    await FunctionsProvider.instance.httpsCallable('registerPushToken').call({
      'token': token,
      'platform': platform,
    });
  } catch (e) {
    debugPrint('[FCM] registerPushToken failed: $e');
  }
}

void _handleMessage(RemoteMessage message) {
  final action = message.data['action'];
  if (action == 'open_requests') {
    navigatorKey.currentState?.pushNamed(AppRouter.friendsHome);
  } else if (action == 'open_friend') {
    final uid = message.data['uid'];
    navigatorKey.currentState?.pushNamed(
      AppRouter.friendDetail,
      arguments: uid,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env laden (optional)
  await dotenv.load(fileName: '.env.dev').catchError((_) {});

  // Firebase init (einheitlich)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  assert(() {
    debugPrint('[Firebase] projectId=' + Firebase.app().options.projectId);
    return true;
  }());

  // App Check (iOS: DeviceCheck für TestFlight/Prod)
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.deviceCheck,
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

  // Push nur aktivieren, wenn explizit gewünscht
  if (kEnablePush) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initMessaging();
  }

  // Lokalisierung
  await initializeDateFormatting();

  // Warm up avatar catalog
  await AvatarCatalog.instance.warmUp(bundle: rootBundle);
  assert(() {
    if (!AvatarCatalog.instance.warmed ||
        !AvatarCatalog.instance.manifestHasPrefix) {
      debugPrint(
          '[AvatarCatalog] manifest_missing_prefix assets/avatars/ – check pubspec.yaml and assets/avatars/');
    }
    return true;
  }());

  // Reports vorbereiten
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
        ChangeNotifierProvider(create: (_) => AvatarInventoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // Friends feature
        Provider<FriendsApi>(create: (_) => FriendsApi()),
        Provider<FriendsSource>(
          create: (_) => FriendsSource(FirebaseFirestore.instance),
        ),
        Provider<UserSearchSource>(
          create: (_) => UserSearchSource(FirebaseFirestore.instance),
        ),
        ChangeNotifierProvider(
          create: (c) => FriendsProvider(
            c.read<FriendsSource>(),
            c.read<FriendsApi>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => FriendSearchProvider(c.read<UserSearchSource>()),
        ),
        ChangeNotifierProvider(
          create: (_) => FriendCalendarProvider(),
        ),
        ChangeNotifierProxyProvider<FriendsProvider, FriendPresenceProvider>(
          create: (_) => FriendPresenceProvider(),
          update: (_, friends, prov) {
            prov ??= FriendPresenceProvider();
            prov.updateUids(friends.friends.map((e) => e.friendUid).toList());
            return prov;
          },
        ),

        // Numeric keypad
        ChangeNotifierProvider<OverlayNumericKeypadController>(
          create: (_) => OverlayNumericKeypadController(),
        ),

        // Membership/Branding/Theme
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

        // Restliche Provider
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
          create: (_) => CreatineProvider(repository: CreatineRepository()),
        ),
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
        ChangeNotifierProvider(create: (_) => WorkoutSessionDurationService()),
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
        // NFC nur unter Android aktiv (wie vorher)
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
