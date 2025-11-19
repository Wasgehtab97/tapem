// lib/bootstrap/legacy_provider_scope.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/drafts/session_draft_repository_impl.dart';
import '../core/providers/all_exercises_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/branding_provider.dart';
import '../core/providers/challenge_provider.dart';
import '../core/providers/exercise_provider.dart';
import '../core/providers/gym_provider.dart';
import '../core/providers/gym_context_state_adapter.dart';
import '../core/providers/gym_scoped_resettable.dart';
import '../core/providers/history_provider.dart';
import '../core/providers/muscle_group_provider.dart';
import '../core/providers/profile_provider.dart';
import '../core/providers/rank_provider.dart';
import '../core/providers/report_provider.dart';
import '../core/providers/rest_stats_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/theme_preference_provider.dart';
import '../core/providers/training_plan_provider.dart';
import '../core/providers/xp_provider.dart';
import '../core/services/workout_session_duration_service.dart';
import '../core/theme/theme_loader.dart';
import '../features/avatars/presentation/providers/avatar_inventory_provider.dart';
import '../features/community/data/community_stats_writer.dart';
import '../features/creatine/data/creatine_repository.dart';
import '../features/creatine/providers/creatine_provider.dart';
import '../features/device/data/repositories/device_repository_impl.dart';
import '../features/device/data/repositories/exercise_repository_impl.dart';
import '../features/device/data/sources/firestore_device_source.dart';
import '../features/device/data/sources/firestore_exercise_source.dart';
import '../features/device/domain/repositories/device_repository.dart';
import '../features/device/domain/repositories/exercise_repository.dart';
import '../features/device/domain/services/exercise_xp_reassignment_service.dart';
import '../features/device/domain/usecases/create_device_usecase.dart';
import '../features/device/domain/usecases/create_exercise_usecase.dart';
import '../features/device/domain/usecases/delete_device_usecase.dart';
import '../features/device/domain/usecases/delete_exercise_usecase.dart';
import '../features/device/domain/usecases/get_device_by_nfc_code.dart';
import '../features/device/domain/usecases/get_devices_for_gym.dart';
import '../features/device/domain/usecases/get_exercises_for_device.dart';
import '../features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import '../features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import '../features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';
import '../features/device/domain/usecases/update_exercise_usecase.dart';
import '../features/device/presentation/controllers/workout_day_controller.dart';
import '../features/feedback/feedback_provider.dart';
import '../features/friends/data/friend_chat_api.dart';
import '../features/friends/data/friend_chat_source.dart';
import '../features/friends/data/friends_api.dart';
import '../features/friends/data/friends_source.dart';
import '../features/friends/data/user_search_source.dart';
import '../features/friends/providers/friend_alerts_provider.dart';
import '../features/friends/providers/friend_calendar_provider.dart';
import '../features/friends/providers/friend_chat_summary_provider.dart';
import '../features/friends/providers/friend_presence_provider.dart';
import '../features/friends/providers/friend_search_provider.dart';
import '../features/friends/providers/friends_provider.dart';
import '../features/gym/data/sources/firestore_gym_source.dart';
import '../features/profile/presentation/providers/powerlifting_provider.dart';
import '../features/report/domain/usecases/get_all_log_timestamps.dart';
import '../features/report/domain/usecases/get_device_usage_stats.dart';
import '../features/rest_stats/data/rest_stats_service.dart';
import '../features/story_session/story_session_service.dart';
import '../features/survey/survey_provider.dart';
import '../services/membership_service.dart';
import '../ui/numeric_keypad/overlay_numeric_keypad.dart';
import '../ui/timer/session_timer_service.dart';
import '../features/nfc/data/nfc_service.dart';
import '../features/nfc/domain/usecases/read_nfc_code.dart';
import '../features/nfc/domain/usecases/write_nfc_tag.dart';
import 'providers.dart';

class LegacyProviderScope extends ConsumerWidget {
  const LegacyProviderScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedPrefs = ref.watch(sharedPreferencesProvider);
    final membership = ref.watch(membershipServiceProvider);
    final usageUC = ref.watch(getDeviceUsageStatsProvider);
    final logsUC = ref.watch(getAllLogTimestampsProvider);
    final brandingSource =
        FirestoreGymSource(firestore: FirebaseFirestore.instance);

    return provider.MultiProvider(
      providers: [
        provider.Provider<SharedPreferences>.value(value: sharedPrefs),
        provider.Provider<MembershipService>.value(value: membership),
        provider.ChangeNotifierProvider<GymScopedStateController>(
          create: (_) => GymScopedStateController(),
        ),
        provider.ChangeNotifierProvider<AuthProvider>(
          create: (c) {
            final controller = c.read<GymScopedStateController>();
            return AuthProvider(
              membershipService: membership,
              gymScopedStateController: controller,
            );
          },
        ),
        provider.ChangeNotifierProxyProvider<AuthProvider, GymContextStateAdapter>(
          create: (_) => GymContextStateAdapter(),
          update: (_, authProvider, adapter) {
            final resolved = adapter ?? GymContextStateAdapter();
            resolved.updateFrom(authProvider);
            return resolved;
          },
        ),
        provider.ChangeNotifierProxyProvider<AuthProvider, BrandingProvider>(
          create: (context) {
            final controller = context.read<GymScopedStateController>();
            final resolved = BrandingProvider(
              source: brandingSource,
              membership: membership,
            );
            resolved.registerGymScopedResettable(controller);
            return resolved;
          },
          update: (context, authProvider, branding) {
            final resolved = branding ?? BrandingProvider(
              source: brandingSource,
              membership: membership,
            );
            resolved.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            resolved.loadBrandingWithGym(
              authProvider.gymCode,
              authProvider.userId,
            );
            return resolved;
          },
        ),
        provider.ChangeNotifierProxyProvider<AuthProvider, GymProvider>(
          create: (context) {
            final resolved = GymProvider();
            resolved.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            return resolved;
          },
          update: (context, authProvider, gymProv) {
            final resolved = gymProv ?? GymProvider();
            resolved.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            final gymId = authProvider.gymCode;
            if (gymId == null || gymId.isEmpty) {
              resolved.resetGymScopedState();
            } else if (resolved.lastRequestedGymId != gymId) {
              unawaited(resolved.loadGymData(gymId));
            }
            return resolved;
          },
        ),
        // TODO(legacy-state): migrate remaining Provider-based services to Riverpod
        provider.Provider<NfcService>(create: (_) => NfcService()),
        provider.Provider<ReadNfcCode>(
            create: (c) => ReadNfcCode(c.read<NfcService>())),
        provider.Provider<WriteNfcTagUseCase>(
            create: (_) => WriteNfcTagUseCase()),
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
        provider.ChangeNotifierProvider(
          create: (_) => AppProvider(preferences: sharedPrefs),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => AvatarInventoryProvider(),
        ),
        provider.ChangeNotifierProvider(create: (_) => SettingsProvider()),
        provider.ChangeNotifierProvider(create: (_) => FriendAlertsProvider()),
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
        provider.ChangeNotifierProvider<OverlayNumericKeypadController>(
          create: (_) => OverlayNumericKeypadController(),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => SessionTimerService(),
        ),
        provider.Provider(
          create: (_) => StorySessionService(
            firestore: FirebaseFirestore.instance,
          ),
        ),
        provider.ChangeNotifierProxyProvider<AuthProvider, ThemePreferenceProvider>(
          create: (_) => ThemePreferenceProvider(),
          update: (_, authProvider, pref) {
            final resolved = pref ?? ThemePreferenceProvider();
            resolved.setUser(authProvider.userId);
            return resolved;
          },
        ),
        provider.ChangeNotifierProxyProvider2<
            BrandingProvider, ThemePreferenceProvider, ThemeLoader>(
          create: (_) => ThemeLoader()..loadDefault(),
          update: (_, brandingProvider, themePref, loader) {
            final resolved = loader ?? (ThemeLoader()..loadDefault());
            resolved.applyBranding(
              brandingProvider.gymId,
              brandingProvider.branding,
              overridePreset: themePref.override,
            );
            return resolved;
          },
        ),
        provider.ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        provider.ChangeNotifierProvider(create: (_) => XpProvider()),
        provider.ChangeNotifierProxyProvider2<
            AuthProvider,
            BrandingProvider,
            WorkoutSessionDurationService>(
          create: (_) => WorkoutSessionDurationService(),
          update: (_, authProvider, brandingProvider, service) {
            final resolved = service ?? WorkoutSessionDurationService();
            unawaited(resolved.setActiveContext(
              uid: authProvider.userId,
              gymId: brandingProvider.gymId,
            ));
            return resolved;
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
              (context, membershipSvc, xp, challenge, duration, authProvider, ctrl) {
            final controller = ctrl ??
                WorkoutDayController(
                  firestore: FirebaseFirestore.instance,
                  membership: membershipSvc,
                  deviceRepository: context.read<DeviceRepository>(),
                  getDevicesForGym: context.read<GetDevicesForGym>(),
                  communityStatsWriter: CommunityStatsWriter(
                    firestore: FirebaseFirestore.instance,
                  ),
                  createDraftRepository: () => SessionDraftRepositoryImpl(),
                );
            controller.updateMembership(membershipSvc);
            controller.setActiveUser(authProvider.userId);
            controller.attachExternalServices(
              xpProvider: xp,
              challengeProvider: challenge,
              sessionDurationService: duration,
            );
            controller.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            return controller;
          },
        ),
        provider.ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        provider.ChangeNotifierProvider(
          create: (c) => RestStatsProvider(service: c.read<RestStatsService>()),
        ),
        provider.ChangeNotifierProvider(create: (_) => HistoryProvider()),
        provider.ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(),
          update: (_, authProvider, profile) {
            final resolved = profile ?? ProfileProvider();
            resolved.updateUserContext(userId: authProvider.userId);
            return resolved;
          },
        ),
        provider.ChangeNotifierProxyProvider2<AuthProvider, GymProvider,
            PowerliftingProvider>(
          create: (context) => PowerliftingProvider(
            firestore: FirebaseFirestore.instance,
            getDevicesForGym: context.read<GetDevicesForGym>(),
            getExercisesForDevice: context.read<GetExercisesForDevice>(),
            membership: context.read<MembershipService>(),
          ),
          update: (context, authProvider, gymProvider, powerlifting) {
            final resolved = powerlifting ?? PowerliftingProvider(
              firestore: FirebaseFirestore.instance,
              getDevicesForGym: context.read<GetDevicesForGym>(),
              getExercisesForDevice: context.read<GetExercisesForDevice>(),
              membership: context.read<MembershipService>(),
            );
            resolved.registerGymScopedResettable(
              context.read<GymScopedStateController>(),
            );
            unawaited(resolved.updateContext(
              userId: authProvider.userId,
              gymId: gymProvider.currentGymId,
            ));
            return resolved;
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
          create: (_) => ExerciseXpReassignmentService(
            firestore: FirebaseFirestore.instance,
          ),
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
          create: (_) => FeedbackProvider(firestore: FirebaseFirestore.instance),
        ),
        provider.ChangeNotifierProvider(create: (_) => RankProvider()),
      ],
      child: _LegacyRiverpodBridge(child: child),
    );
  }
}

class _LegacyRiverpodBridge extends StatefulWidget {
  const _LegacyRiverpodBridge({required this.child});

  final Widget child;

  @override
  State<_LegacyRiverpodBridge> createState() => _LegacyRiverpodBridgeState();
}

class _LegacyRiverpodBridgeState extends State<_LegacyRiverpodBridge> {
  late final AuthProvider _auth;
  late final BrandingProvider _branding;
  late final GymProvider _gym;
  late final List<Override> _overrides;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auth = provider.Provider.of<AuthProvider>(context, listen: false);
    _branding = provider.Provider.of<BrandingProvider>(context, listen: false);
    _gym = provider.Provider.of<GymProvider>(context, listen: false);
    _overrides = [
      authControllerProvider.overrideWith((ref) => _auth),
      authViewStateProvider.overrideWithProvider(
        Provider<AuthViewState>((ref) {
          final auth = ref.watch(authControllerProvider);
          return AuthViewState.fromAuth(auth);
        }),
      ),
      brandingProvider.overrideWith((ref) => _branding),
      gymProvider.overrideWith((ref) => _gym),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: _overrides,
      child: widget.child,
    );
  }
}
