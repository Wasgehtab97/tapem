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
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'features/community/presentation/providers/community_providers.dart'
    show currentGymIdProvider;

import 'firebase_options.dart';
import 'app_router.dart';
import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/core/providers/app_provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
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
import 'package:tapem/core/providers/rest_stats_provider.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/features/community/data/community_stats_writer.dart';
import 'package:tapem/features/feedback/feedback_provider.dart';
import 'package:tapem/features/survey/survey_provider.dart';
import 'package:tapem/features/friends/data/friends_api.dart';
import 'package:tapem/features/friends/data/friends_source.dart';
import 'package:tapem/features/friends/data/user_search_source.dart';
import 'package:tapem/features/friends/data/friend_chat_api.dart';
import 'package:tapem/features/friends/data/friend_chat_source.dart';
import 'package:tapem/features/friends/providers/friends_provider.dart';
import 'package:tapem/features/friends/providers/friend_calendar_provider.dart';
import 'package:tapem/features/friends/providers/friend_alerts_provider.dart';
import 'package:tapem/features/friends/providers/friend_presence_provider.dart';
import 'package:tapem/features/friends/providers/friend_chat_summary_provider.dart';
import 'package:tapem/features/creatine/data/creatine_repository.dart';
import 'package:tapem/features/creatine/providers/creatine_provider.dart';
import 'package:tapem/features/friends/providers/friend_search_provider.dart';
import 'package:tapem/features/profile/presentation/providers/powerlifting_provider.dart';
import 'package:tapem/features/story_session/presentation/widgets/story_session_highlights_listener.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'features/gym/data/sources/firestore_gym_source.dart';
import 'ui/numeric_keypad/overlay_numeric_keypad.dart';
import 'ui/timer/session_timer_service.dart';
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
import 'features/device/presentation/controllers/workout_day_controller.dart';

import 'features/device/data/sources/firestore_exercise_source.dart';
import 'features/device/data/repositories/exercise_repository_impl.dart';
import 'features/device/domain/repositories/exercise_repository.dart';
import 'features/device/domain/usecases/get_exercises_for_device.dart';
import 'features/device/domain/services/exercise_xp_reassignment_service.dart';
import 'features/device/domain/usecases/create_exercise_usecase.dart';
import 'features/device/domain/usecases/delete_exercise_usecase.dart';
import 'features/device/domain/usecases/update_exercise_usecase.dart';
import 'features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';
import 'features/rest_stats/data/rest_stats_service.dart';

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

Future<void> _initializeFirebaseApp() async {
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Falls der Prozess im Hintergrund startet, Firebase erneut initialisieren.
  await _initializeFirebaseApp();
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
  await _initializeFirebaseApp();
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
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    provider.MultiProvider(
      providers: [
          // NFC
          provider.Provider<NfcService>(create: (_) => NfcService()),
          provider.Provider<ReadNfcCode>(
              create: (c) => ReadNfcCode(c.read<NfcService>())),
          provider.Provider<WriteNfcTagUseCase>(create: (_) => WriteNfcTagUseCase()),

        // Device
        provider.Provider<DeviceRepository>(
          create: (_) => DeviceRepositoryImpl(FirestoreDeviceSource()),
        ),
        provider.Provider<CreateDeviceUseCase>(
          create: (c) => CreateDeviceUseCase(c.read<DeviceRepository>()),
        ),
        provider.Provider<GetDevicesForGym>(
          create: (c) => GetDevicesForGym(c.read<DeviceRepository>()),
        ),
        provider.Provider<GetDeviceByNfcCode>(
          create: (c) => GetDeviceByNfcCode(c.read<DeviceRepository>()),
        ),
        provider.Provider<DeleteDeviceUseCase>(
          create: (c) => DeleteDeviceUseCase(c.read<DeviceRepository>()),
        ),
        provider.Provider<UpdateDeviceMuscleGroupsUseCase>(
          create: (c) =>
              UpdateDeviceMuscleGroupsUseCase(c.read<DeviceRepository>()),
        ),
        provider.Provider<SetDeviceMuscleGroupsUseCase>(
          create: (c) =>
              SetDeviceMuscleGroupsUseCase(c.read<DeviceRepository>()),
        ),

        // Exercise
        provider.Provider<ExerciseRepository>(
          create: (_) => ExerciseRepositoryImpl(FirestoreExerciseSource()),
        ),
        provider.Provider<GetExercisesForDevice>(
          create: (c) => GetExercisesForDevice(c.read<ExerciseRepository>()),
        ),
        provider.Provider<CreateExerciseUseCase>(
          create: (c) => CreateExerciseUseCase(c.read<ExerciseRepository>()),
        ),
        provider.Provider<DeleteExerciseUseCase>(
          create: (c) => DeleteExerciseUseCase(c.read<ExerciseRepository>()),
        ),
        provider.Provider<UpdateExerciseUseCase>(
          create: (c) => UpdateExerciseUseCase(c.read<ExerciseRepository>()),
        ),
        provider.Provider<UpdateExerciseMuscleGroupsUseCase>(
          create: (c) =>
              UpdateExerciseMuscleGroupsUseCase(c.read<ExerciseRepository>()),
        ),
        provider.Provider<RestStatsService>(
          create: (_) => RestStatsService(firestore: FirebaseFirestore.instance),
        ),

        // App state
        provider.ChangeNotifierProvider(
          create: (_) => AppProvider(preferences: sharedPrefs),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => GymScopedStateController(),
        ),
        provider.ChangeNotifierProvider(
          create: (context) => AuthProvider(
            gymScopedStateController: context.read<GymScopedStateController>(),
          ),
        ),
        provider.ProxyProvider<AuthProvider, GymContextState>(
          update: (_, auth, __) => auth,
        ),
        provider.ChangeNotifierProvider(create: (_) => AvatarInventoryProvider()),
        provider.ChangeNotifierProvider(create: (_) => SettingsProvider()),
        provider.ChangeNotifierProvider(create: (_) => FriendAlertsProvider()),

        // Friends feature
        provider.Provider<FriendsApi>(create: (_) => FriendsApi()),
        provider.Provider<FriendsSource>(
          create: (_) => FriendsSource(FirebaseFirestore.instance),
        ),
        provider.Provider<UserSearchSource>(
          create: (_) => UserSearchSource(FirebaseFirestore.instance),
        ),
        provider.Provider<FriendChatApi>(create: (_) => FriendChatApi()),
        provider.Provider<FriendChatSource>(
          create: (_) => FriendChatSource(FirebaseFirestore.instance),
        ),
        provider.ChangeNotifierProvider(
          create: (c) => FriendsProvider(
            c.read<FriendsSource>(),
            c.read<FriendsApi>(),
          ),
        ),
        provider.ChangeNotifierProvider(
          create: (c) => FriendChatSummaryProvider(
            c.read<FriendChatSource>(),
            c.read<FriendChatApi>(),
          ),
        ),
        provider.ChangeNotifierProvider(
          create: (c) => FriendSearchProvider(c.read<UserSearchSource>()),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => FriendCalendarProvider(),
        ),
        provider.ChangeNotifierProxyProvider<FriendsProvider, FriendPresenceProvider>(
          create: (_) => FriendPresenceProvider(),
          update: (_, friends, prov) {
            prov ??= FriendPresenceProvider();
            prov.updateUids(friends.friends.map((e) => e.friendUid).toList());
            return prov;
          },
        ),

        // Numeric keypad
        provider.ChangeNotifierProvider<OverlayNumericKeypadController>(
          create: (_) => OverlayNumericKeypadController(),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => SessionTimerService(),
        ),

        // Membership/Branding/Theme
        provider.Provider<MembershipService>(
          create: (_) => FirestoreMembershipService(),
        ),
        provider.Provider(
          create: (_) => StorySessionService(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        provider.ChangeNotifierProxyProvider2<
          AuthProvider,
          MembershipService,
          BrandingProvider
        >(
          create: (c) => BrandingProvider(
            source: FirestoreGymSource(firestore: FirebaseFirestore.instance),
            membership: c.read<MembershipService>(),
          ),
          update: (context, auth, m, prov) {
            final p =
                prov ??
                BrandingProvider(
                  source: FirestoreGymSource(
                    firestore: FirebaseFirestore.instance,
                  ),
                  membership: m,
                );
            p.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            p.loadBrandingWithGym(auth.gymCode, auth.userId);
            return p;
          },
        ),
        provider.ChangeNotifierProxyProvider<AuthProvider, ThemePreferenceProvider>(
          create: (_) => ThemePreferenceProvider(),
          update: (_, auth, provider) {
            final pref = provider ?? ThemePreferenceProvider();
            pref.setUser(auth.userId);
            return pref;
          },
        ),
        provider.ChangeNotifierProxyProvider2<
            BrandingProvider, ThemePreferenceProvider, ThemeLoader>(
          create: (_) => ThemeLoader()..loadDefault(),
          update: (_, branding, themePref, loader) {
            final l = loader ?? (ThemeLoader()..loadDefault());
            l.applyBranding(
              branding.gymId,
              branding.branding,
              overridePreset: themePref.override,
            );
            return l;
          },
        ),

        // Restliche Provider
        provider.ChangeNotifierProxyProvider2<
            AuthProvider, GymScopedStateController, GymProvider>(
          create: (_) => GymProvider(),
          update: (_, auth, controller, gym) {
            final prov = gym ?? GymProvider();
            prov.registerGymScopedResettable(controller);
            final gymId = auth.gymCode;
            if (gymId == null || gymId.isEmpty) {
              prov.resetGymScopedState();
            } else if (prov.lastRequestedGymId != gymId) {
              unawaited(prov.loadGymData(gymId));
            }
            return prov;
          },
        ),
        provider.ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        provider.ChangeNotifierProvider(create: (_) => XpProvider()),
        provider.ChangeNotifierProxyProvider2<
            AuthProvider,
            BrandingProvider,
            WorkoutSessionDurationService>(
          create: (_) => WorkoutSessionDurationService(),
          update: (_, auth, branding, service) {
            final svc = service ?? WorkoutSessionDurationService();
            unawaited(svc.setActiveContext(
              uid: auth.userId,
              gymId: branding.gymId,
            ));
            return svc;
          },
        ),
        provider.ChangeNotifierProxyProvider5<
            MembershipService,
            XpProvider,
            ChallengeProvider,
            WorkoutSessionDurationService,
            AuthProvider,
            WorkoutDayController>(
          create: (context) => WorkoutDayController(
            firestore: FirebaseFirestore.instance,
            membership: context.read<MembershipService>(),
            deviceRepository: context.read<DeviceRepository>(),
            getDevicesForGym: context.read<GetDevicesForGym>(),
            communityStatsWriter: CommunityStatsWriter(
              firestore: FirebaseFirestore.instance,
            ),
            createDraftRepository: () => SessionDraftRepositoryImpl(),
          ),
          update:
              (context, membership, xp, challenge, duration, auth, controller) {
            final ctrl = controller ??
                WorkoutDayController(
                  firestore: FirebaseFirestore.instance,
                  membership: membership,
                  deviceRepository: context.read<DeviceRepository>(),
                  getDevicesForGym: context.read<GetDevicesForGym>(),
                  communityStatsWriter: CommunityStatsWriter(
                    firestore: FirebaseFirestore.instance,
                  ),
                  createDraftRepository: () => SessionDraftRepositoryImpl(),
                );
            ctrl.updateMembership(membership);
            ctrl.setActiveUser(auth.userId);
            ctrl.attachExternalServices(
              xpProvider: xp,
              challengeProvider: challenge,
              sessionDurationService: duration,
            );
            ctrl.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            return ctrl;
          },
        ),
        provider.ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        provider.ChangeNotifierProvider(
          create: (c) => RestStatsProvider(service: c.read<RestStatsService>()),
        ),
        provider.ChangeNotifierProvider(create: (_) => HistoryProvider()),
        provider.ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, auth, provider) {
            final prov = provider ?? ProfileProvider();
            prov.updateUserContext(userId: auth.userId);
            return prov;
          },
        ),
        provider.ChangeNotifierProxyProvider2<AuthProvider, GymProvider,
            PowerliftingProvider>(
          create: (c) => PowerliftingProvider(
            firestore: FirebaseFirestore.instance,
            getDevicesForGym: c.read<GetDevicesForGym>(),
            getExercisesForDevice: c.read<GetExercisesForDevice>(),
            membership: c.read<MembershipService>(),
          ),
          update: (context, auth, gym, provider) {
            final prov = provider ?? PowerliftingProvider(
              firestore: FirebaseFirestore.instance,
              getDevicesForGym: context.read<GetDevicesForGym>(),
              getExercisesForDevice: context.read<GetExercisesForDevice>(),
              membership: context.read<MembershipService>(),
            );
            prov.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            unawaited(prov.updateContext(
              userId: auth.userId,
              gymId: gym.currentGymId,
            ));
            return prov;
          },
        ),
        provider.ChangeNotifierProvider(
          create: (_) => CreatineProvider(repository: CreatineRepository()),
        ),
        provider.ChangeNotifierProvider(
          create: (c) =>
              MuscleGroupProvider(membership: c.read<MembershipService>()),
        ),
        provider.Provider(
          create: (_) =>
              ExerciseXpReassignmentService(firestore: FirebaseFirestore.instance),
        ),
        provider.ChangeNotifierProvider(
          create: (c) => ExerciseProvider(
            getEx: c.read<GetExercisesForDevice>(),
            createEx: c.read<CreateExerciseUseCase>(),
            deleteEx: c.read<DeleteExerciseUseCase>(),
            updateEx: c.read<UpdateExerciseUseCase>(),
            updateMuscles: c.read<UpdateExerciseMuscleGroupsUseCase>(),
            xpReassignment: c.read<ExerciseXpReassignmentService>(),
          ),
        ),
        provider.ChangeNotifierProvider(
          create: (c) =>
              AllExercisesProvider(getEx: c.read<GetExercisesForDevice>()),
        ),
        provider.ChangeNotifierProvider(
          create: (_) =>
              ReportProvider(getUsageStats: usageUC, getLogTimestamps: logsUC),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => SurveyProvider(firestore: FirebaseFirestore.instance),
        ),
        provider.ChangeNotifierProvider(
          create: (_) =>
              FeedbackProvider(firestore: FirebaseFirestore.instance),
        ),
        provider.ChangeNotifierProvider(create: (_) => RankProvider()),
      ],
      child: const _RiverpodApp(),
    ),
  );
}

class _RiverpodApp extends StatelessWidget {
  const _RiverpodApp();

  @override
  Widget build(BuildContext context) {
    final gymId = context.watch<AuthProvider>().gymCode ?? '';
    return riverpod.ProviderScope(
      overrides: [
        currentGymIdProvider.overrideWithValue(gymId),
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
        app = StorySessionHighlightsListener(
          navigatorKey: navigatorKey,
          child: app,
        );
        return OverlayNumericKeypadHost(
          controller: keypad,
          outsideTapMode: OutsideTapMode.closeAfterTap,
          theme: NumericKeypadTheme.fromContext(context),
          child: app,
        );
      },
    );
  }
}
