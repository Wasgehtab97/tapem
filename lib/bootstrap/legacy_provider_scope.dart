// lib/bootstrap/legacy_provider_scope.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';

import '../features/device/providers/all_exercises_provider.dart';
import '../core/providers/app_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/branding_provider.dart';
import '../core/providers/challenge_provider.dart';
import '../features/device/providers/exercise_provider.dart';
import '../core/providers/gym_context_state_adapter.dart';
import '../core/providers/gym_provider.dart';
import '../core/providers/gym_scoped_resettable.dart';
import '../core/providers/muscle_group_provider.dart';
import '../core/providers/profile_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/theme_preference_provider.dart';
import '../features/training_plan/providers/training_plan_provider.dart';
import '../core/providers/xp_provider.dart';
import '../core/services/workout_session_duration_service.dart';
import '../core/theme/theme_loader.dart';
import '../features/avatars/presentation/providers/avatar_inventory_provider.dart';
import '../features/creatine/providers/creatine_provider.dart';
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
import '../features/device/providers/device_riverpod.dart';
import '../features/device/providers/workout_day_controller_provider.dart';
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
import '../features/friends/providers/friends_riverpod.dart';
import '../features/nfc/data/nfc_service.dart';
import '../features/nfc/domain/usecases/read_nfc_code.dart';
import '../features/nfc/domain/usecases/write_nfc_tag.dart';
import '../features/nfc/providers/nfc_providers.dart';
import '../features/profile/presentation/providers/powerlifting_provider.dart';
import '../features/report/providers/report_providers.dart';
import '../features/rest_stats/data/rest_stats_service.dart';
import '../features/story_session/story_session_service.dart';
import '../services/membership_service.dart';
import '../ui/numeric_keypad/overlay_numeric_keypad.dart';
import '../ui/timer/session_timer_service.dart';
import 'providers.dart';

class LegacyProviderScope extends ConsumerWidget {
  const LegacyProviderScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedPrefs = ref.watch(sharedPreferencesProvider);
    final membership = ref.watch(membershipServiceProvider);
    final gymScopedController = ref.watch(gymScopedStateControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final gymContext = ref.watch(gymContextStateAdapterProvider);
    final branding = ref.watch(brandingProvider);
    final gym = ref.watch(gymProvider);

    final adapters = <provider.SingleChildWidget>[
      provider.Provider<SharedPreferences>.value(value: sharedPrefs),
      provider.Provider<MembershipService>.value(value: membership),
      provider.ChangeNotifierProvider<GymScopedStateController>.value(
        value: gymScopedController,
      ),
      provider.ChangeNotifierProvider<AuthProvider>.value(value: auth),
      provider.ChangeNotifierProvider<GymContextStateAdapter>.value(
        value: gymContext,
      ),
      provider.ChangeNotifierProvider<BrandingProvider>.value(value: branding),
      provider.ChangeNotifierProvider<GymProvider>.value(value: gym),

      // Legacy UI adapters fed by Riverpod providers.
      provider.Provider<NfcService>.value(value: ref.watch(nfcServiceProvider)),
      provider.Provider<ReadNfcCode>.value(value: ref.watch(readNfcCodeProvider)),
      provider.Provider<WriteNfcTagUseCase>.value(
        value: ref.watch(writeNfcTagUseCaseProvider),
      ),
      provider.Provider<DeviceRepository>.value(
        value: ref.watch(deviceRepositoryProvider),
      ),
      provider.Provider<CreateDeviceUseCase>.value(
        value: ref.watch(createDeviceUseCaseProvider),
      ),
      provider.Provider<GetDevicesForGym>.value(
        value: ref.watch(getDevicesForGymProvider),
      ),
      provider.Provider<GetDeviceByNfcCode>.value(
        value: ref.watch(getDeviceByNfcCodeProvider),
      ),
      provider.Provider<DeleteDeviceUseCase>.value(
        value: ref.watch(deleteDeviceUseCaseProvider),
      ),
      provider.Provider<UpdateDeviceMuscleGroupsUseCase>.value(
        value: ref.watch(updateDeviceMuscleGroupsUseCaseProvider),
      ),
      provider.Provider<SetDeviceMuscleGroupsUseCase>.value(
        value: ref.watch(setDeviceMuscleGroupsUseCaseProvider),
      ),
      provider.Provider<ExerciseRepository>.value(
        value: ref.watch(exerciseRepositoryProvider),
      ),
      provider.Provider<GetExercisesForDevice>.value(
        value: ref.watch(getExercisesForDeviceProvider),
      ),
      provider.Provider<CreateExerciseUseCase>.value(
        value: ref.watch(createExerciseUseCaseProvider),
      ),
      provider.Provider<DeleteExerciseUseCase>.value(
        value: ref.watch(deleteExerciseUseCaseProvider),
      ),
      provider.Provider<UpdateExerciseUseCase>.value(
        value: ref.watch(updateExerciseUseCaseProvider),
      ),
      provider.Provider<UpdateExerciseMuscleGroupsUseCase>.value(
        value: ref.watch(updateExerciseMuscleGroupsUseCaseProvider),
      ),
      provider.Provider<RestStatsService>.value(
        value: ref.watch(restStatsServiceProvider),
      ),
      provider.ChangeNotifierProvider<AppProvider>.value(
        value: ref.watch(appProvider),
      ),
      provider.ChangeNotifierProvider<AvatarInventoryProvider>.value(
        value: ref.watch(avatarInventoryProvider),
      ),
      provider.ChangeNotifierProvider<SettingsProvider>.value(
        value: ref.watch(settingsProvider),
      ),
      provider.ChangeNotifierProvider<FriendAlertsProvider>.value(
        value: ref.watch(friendAlertsProvider),
      ),
      provider.Provider<FriendsApi>.value(value: ref.watch(friendsApiProvider)),
      provider.Provider<FriendsSource>.value(
        value: ref.watch(friendsSourceProvider),
      ),
      provider.Provider<UserSearchSource>.value(
        value: ref.watch(userSearchSourceProvider),
      ),
      provider.Provider<FriendChatApi>.value(
        value: ref.watch(friendChatApiProvider),
      ),
      provider.Provider<FriendChatSource>.value(
        value: ref.watch(friendChatSourceProvider),
      ),
      provider.ChangeNotifierProvider<FriendsProvider>.value(
        value: ref.watch(friendsProvider),
      ),
      provider.ChangeNotifierProvider<FriendChatSummaryProvider>.value(
        value: ref.watch(friendChatSummaryProvider),
      ),
      provider.ChangeNotifierProvider<FriendSearchProvider>.value(
        value: ref.watch(friendSearchProvider),
      ),
      provider.ChangeNotifierProvider<FriendCalendarProvider>.value(
        value: ref.watch(friendCalendarProvider),
      ),
      provider.ChangeNotifierProvider<FriendPresenceProvider>.value(
        value: ref.watch(friendPresenceProvider),
      ),
      provider.ChangeNotifierProvider<OverlayNumericKeypadController>.value(
        value: ref.watch(overlayNumericKeypadControllerProvider),
      ),
      provider.ChangeNotifierProvider<SessionTimerService>.value(
        value: ref.watch(sessionTimerServiceProvider),
      ),
      provider.Provider<StorySessionService>.value(
        value: ref.watch(storySessionServiceProvider),
      ),
      provider.ChangeNotifierProvider<ThemePreferenceProvider>.value(
        value: ref.watch(themePreferenceProvider),
      ),
      provider.ChangeNotifierProvider<ThemeLoader>.value(
        value: ref.watch(themeLoaderProvider),
      ),
      provider.ChangeNotifierProvider<ChallengeProvider>.value(
        value: ref.watch(challengeProvider),
      ),
      provider.ChangeNotifierProvider<XpProvider>.value(
        value: ref.watch(xpProvider),
      ),
      provider.ChangeNotifierProvider<WorkoutSessionDurationService>.value(
        value: ref.watch(workoutSessionDurationServiceProvider),
      ),
      provider.ChangeNotifierProvider<WorkoutDayController>.value(
        value: ref.watch(workoutDayControllerProvider),
      ),
      provider.ChangeNotifierProvider<TrainingPlanProvider>.value(
        value: ref.watch(trainingPlanProvider),
      ),
      provider.ChangeNotifierProvider<ProfileProvider>.value(
        value: ref.watch(profileProvider),
      ),
      provider.ChangeNotifierProvider<PowerliftingProvider>.value(
        value: ref.watch(powerliftingProvider),
      ),
      provider.ChangeNotifierProvider<CreatineProvider>.value(
        value: ref.watch(creatineProvider),
      ),
      provider.ChangeNotifierProvider<MuscleGroupProvider>.value(
        value: ref.watch(muscleGroupProvider),
      ),
      provider.Provider<ExerciseXpReassignmentService>.value(
        value: ref.watch(exerciseXpReassignmentServiceProvider),
      ),
      provider.ChangeNotifierProvider<ExerciseProvider>.value(
        value: ref.watch(exerciseProvider),
      ),
      provider.ChangeNotifierProvider<AllExercisesProvider>.value(
        value: ref.watch(allExercisesProvider),
      ),
    ];

    return provider.MultiProvider(
      providers: adapters,
      child: child,
    );
  }
}
