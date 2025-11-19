import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tapem/bootstrap/bootstrap.dart';
import 'package:tapem/bootstrap/legacy_provider_scope.dart';
import 'package:tapem/bootstrap/providers.dart';
import 'package:tapem/core/app/tapem_app.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/providers/branding_provider.dart';
import 'package:tapem/core/providers/challenge_provider.dart';
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/gym_scoped_resettable.dart';
import 'package:tapem/core/providers/muscle_group_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/core/providers/settings_provider.dart';
import 'package:tapem/core/providers/theme_preference_provider.dart';
import 'package:tapem/core/providers/xp_provider.dart';
import 'package:tapem/core/services/workout_session_duration_service.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/features/creatine/providers/creatine_provider.dart';
import 'package:tapem/features/device/domain/models/device.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/repositories/exercise_repository.dart';
import 'package:tapem/features/device/domain/services/exercise_xp_reassignment_service.dart';
import 'package:tapem/features/device/domain/usecases/create_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/create_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_device_usecase.dart';
import 'package:tapem/features/device/domain/usecases/delete_exercise_usecase.dart';
import 'package:tapem/features/device/domain/usecases/get_device_by_nfc_code.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/usecases/get_exercises_for_device.dart';
import 'package:tapem/features/device/domain/usecases/set_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_device_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_muscle_groups_usecase.dart';
import 'package:tapem/features/device/domain/usecases/update_exercise_usecase.dart';
import 'package:tapem/features/device/presentation/controllers/workout_day_controller.dart';
import 'package:tapem/features/device/providers/all_exercises_provider.dart';
import 'package:tapem/features/device/providers/exercise_provider.dart';
import 'package:tapem/features/device/providers/workout_day_controller_provider.dart';
import 'package:tapem/features/gym/domain/models/branding.dart';
import 'package:tapem/features/gym/domain/models/gym_config.dart';
import 'package:tapem/features/gym/presentation/screens/select_gym_screen.dart';
import 'package:tapem/features/nfc/data/nfc_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/features/nfc/domain/usecases/write_nfc_tag.dart';
import 'package:tapem/features/profile/presentation/providers/powerlifting_provider.dart';
import 'package:tapem/features/report/domain/models/device_usage_stat.dart';
import 'package:tapem/features/report/domain/repositories/report_repository.dart';
import 'package:tapem/features/report/domain/usecases/get_all_log_timestamps.dart';
import 'package:tapem/features/report/domain/usecases/get_device_usage_stats.dart';
import 'package:tapem/features/rest_stats/data/rest_stats_service.dart';
import 'package:tapem/features/story_session/story_session_service.dart';
import 'package:tapem/features/training_plan/providers/training_plan_provider.dart';
import 'package:tapem/services/membership_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.testLoad(fileInput: 'APP_NAME=Tapem');
  });

  group('TapemApp + LegacyProviderScope', () {
    testWidgets('handles gym selection flow, resets and theme updates',
        (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final sharedPrefs = await SharedPreferences.getInstance();
      final reportRepo = _FakeReportRepository();
      final bootstrap = BootstrapResult(
        sharedPreferences: sharedPrefs,
        getUsageStats: GetDeviceUsageStats(reportRepo),
        getLogTimestamps: GetAllLogTimestamps(reportRepo),
      );

      final fakeAuth = _FakeAuthProvider()..setUserName('Tester');
      final fakeBranding = _FakeBrandingProvider();
      final fakeGym = _FakeGymProvider();
      final fakeThemePrefs = _FakeThemePreferenceProvider();
      final fakeWorkoutDay = _FakeWorkoutDayController();
      final fakeMembership = _FakeMembershipService();

      final overrides = _buildLegacyOverrides(
        bootstrap: bootstrap,
        auth: fakeAuth,
        branding: fakeBranding,
        gym: fakeGym,
        themePrefs: fakeThemePrefs,
        workoutDay: fakeWorkoutDay,
        membership: fakeMembership,
      );

      fakeAuth.updateState(isLoading: false, error: 'boom');

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const TapemApp(),
        ),
      );

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.textContaining('Fehler beim Laden'), findsOneWidget);

      var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final initialPrimary = materialApp.theme.colorScheme.primary;

      fakeBranding.emitBranding(
        'club',
        Branding(primaryColor: '#5500FF', secondaryColor: '#00FFAA'),
      );
      await tester.pump();
      materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.theme.colorScheme.primary, isNot(initialPrimary));

      fakeAuth.updateState(
        isLoading: false,
        isLoggedIn: true,
        status: GymContextStatus.missingSelection,
        userId: 'user-1',
        gymCodes: const ['club', 'lifthouse'],
        error: null,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.byType(SelectGymScreen), findsOneWidget);
      expect(find.text('club'), findsOneWidget);

      final resetsBeforeSwitch = fakeWorkoutDay.resetCount;
      await fakeAuth.switchGym('club');
      await tester.pump();
      expect(fakeWorkoutDay.resetCount, greaterThan(resetsBeforeSwitch));

      fakeBranding.emitBranding(
        'club',
        Branding(primaryColor: '#FF5500', secondaryColor: '#0011FF'),
      );
      await tester.pump();
      materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.theme.colorScheme.primary,
          equals(const Color(0xFFFF5500)));

      final resetsAfterSwitch = fakeWorkoutDay.resetCount;
      await fakeAuth.logout();
      await tester.pump();
      expect(fakeWorkoutDay.resetCount, greaterThan(resetsAfterSwitch));
      expect(tester.takeException(), isNull);
    });

    testWidgets('LegacyProviderScope uses authViewState overrides safely',
        (tester) async {
      SharedPreferences.setMockInitialValues(const {});
      final sharedPrefs = await SharedPreferences.getInstance();
      final repo = _FakeReportRepository();
      final bootstrap = BootstrapResult(
        sharedPreferences: sharedPrefs,
        getUsageStats: GetDeviceUsageStats(repo),
        getLogTimestamps: GetAllLogTimestamps(repo),
      );

      final fakeAuth = _FakeAuthProvider()..setUserName('Tester');
      final fakeBranding = _FakeBrandingProvider();
      final fakeGym = _FakeGymProvider();
      final fakeThemePrefs = _FakeThemePreferenceProvider();
      final fakeWorkoutDay = _FakeWorkoutDayController();
      final fakeMembership = _FakeMembershipService();

      final overrides = _buildLegacyOverrides(
        bootstrap: bootstrap,
        auth: fakeAuth,
        branding: fakeBranding,
        gym: fakeGym,
        themePrefs: fakeThemePrefs,
        workoutDay: fakeWorkoutDay,
        membership: fakeMembership,
      );

      final authState = StateController<AuthViewState>(_authState(
        isLoggedIn: true,
        status: GymContextStatus.ready,
        gymCode: 'club',
        userId: 'user-1',
      ));

      overrides.add(
        authViewStateProvider.overrideWith((ref) => authState.state),
      );

      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: LegacyProviderScope(child: SizedBox()),
          ),
        ),
      );

      await tester.pump();
      expect(tester.takeException(), isNull);

      authState.state = _authState(error: 'boom');
      container.invalidate(authViewStateProvider);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

AuthViewState _authState({
  bool isLoading = false,
  bool isLoggedIn = false,
  bool isAdmin = false,
  GymContextStatus status = GymContextStatus.unknown,
  String? gymCode,
  String? userId,
  String? error,
}) {
  return AuthViewState(
    isLoading: isLoading,
    isLoggedIn: isLoggedIn,
    isAdmin: isAdmin,
    gymContextStatus: status,
    gymCode: gymCode,
    userId: userId,
    error: error,
  );
}

List<Override> _buildLegacyOverrides({
  required BootstrapResult bootstrap,
  required _FakeAuthProvider auth,
  required _FakeBrandingProvider branding,
  required _FakeGymProvider gym,
  required _FakeThemePreferenceProvider themePrefs,
  required _FakeWorkoutDayController workoutDay,
  required _FakeMembershipService membership,
}) {
  final xp = _MockXpProvider();
  final challenge = _MockChallengeProvider();
  final workoutDuration = _MockWorkoutSessionDurationService();
  final trainingPlan = _MockTrainingPlanProvider();
  final profile = _MockProfileProvider();
  final powerlifting = _MockPowerliftingProvider();
  final creatine = _MockCreatineProvider();
  final muscleGroups = _MockMuscleGroupProvider();
  final exercises = _MockExerciseProvider();
  final allExercises = _MockAllExercisesProvider();
  final avatarInventory = _MockAvatarInventoryProvider();
  final settings = FakeSettingsProvider();
  final restStats = _MockRestStatsService();
  final storySession = _MockStorySessionService();
  final xpReassignment = _MockExerciseXpReassignmentService();
  final nfcService = _MockNfcService();
  final readNfc = _MockReadNfcCode();
  final writeNfc = _MockWriteNfcTagUseCase();
  final deviceRepo = _MockDeviceRepository();
  final getDevices = _MockGetDevicesForGym();
  final getDeviceByCode = _MockGetDeviceByNfcCode();
  final deleteDevice = _MockDeleteDeviceUseCase();
  final createDevice = _MockCreateDeviceUseCase();
  final setDeviceMuscles = _MockSetDeviceMuscleGroupsUseCase();
  final updateDeviceMuscles = _MockUpdateDeviceMuscleGroupsUseCase();
  final exerciseRepo = _MockExerciseRepository();
  final getExercises = _MockGetExercisesForDevice();
  final createExercise = _MockCreateExerciseUseCase();
  final deleteExercise = _MockDeleteExerciseUseCase();
  final updateExercise = _MockUpdateExerciseUseCase();
  final updateExerciseMuscles = _MockUpdateExerciseMuscleGroupsUseCase();

  return [
    ...bootstrap.toOverrides(),
    membershipServiceProvider.overrideWithValue(membership),
    authControllerProvider.overrideWith((ref) {
      auth.attachGymScopedController(ref.read(gymScopedStateControllerProvider));
      ref.onDispose(auth.dispose);
      return auth;
    }),
    brandingProvider.overrideWith((ref) {
      branding.registerGymScopedResettable(
        ref.read(gymScopedStateControllerProvider),
      );
      ref.onDispose(branding.dispose);
      return branding;
    }),
    gymProvider.overrideWith((ref) {
      gym.registerGymScopedResettable(
        ref.read(gymScopedStateControllerProvider),
      );
      ref.onDispose(gym.dispose);
      return gym;
    }),
    themePreferenceProvider.overrideWith((ref) {
      themePrefs.setUser(ref.read(authViewStateProvider).userId);
      ref.listen<AuthViewState>(authViewStateProvider, (_, next) {
        themePrefs.setUser(next.userId);
      }, fireImmediately: false);
      return themePrefs;
    }),
    workoutDayControllerProvider.overrideWith((ref) {
      workoutDay.registerGymScopedResettable(
        ref.read(gymScopedStateControllerProvider),
      );
      workoutDay.attachAuth(ref.read(authViewStateProvider));
      ref.listen<AuthViewState>(authViewStateProvider, (_, next) {
        workoutDay.attachAuth(next);
      }, fireImmediately: false);
      ref.onDispose(workoutDay.dispose);
      return workoutDay;
    }),
    xpProvider.overrideWith((ref) => xp),
    challengeProvider.overrideWith((ref) => challenge),
    workoutSessionDurationServiceProvider.overrideWith((ref) => workoutDuration),
    trainingPlanProvider.overrideWith((ref) => trainingPlan),
    profileProvider.overrideWith((ref) => profile),
    powerliftingProvider.overrideWith((ref) => powerlifting),
    creatineProvider.overrideWith((ref) => creatine),
    muscleGroupProvider.overrideWith((ref) => muscleGroups),
    exerciseProvider.overrideWith((ref) => exercises),
    allExercisesProvider.overrideWith((ref) => allExercises),
    avatarInventoryProvider.overrideWith((ref) => avatarInventory),
    settingsProvider.overrideWith((ref) => settings),
    restStatsServiceProvider.overrideWithValue(restStats),
    storySessionServiceProvider.overrideWithValue(storySession),
    exerciseXpReassignmentServiceProvider.overrideWithValue(xpReassignment),
    nfcServiceProvider.overrideWithValue(nfcService),
    readNfcCodeProvider.overrideWithValue(readNfc),
    writeNfcTagUseCaseProvider.overrideWithValue(writeNfc),
    deviceRepositoryProvider.overrideWithValue(deviceRepo),
    getDevicesForGymProvider.overrideWithValue(getDevices),
    getDeviceByNfcCodeProvider.overrideWithValue(getDeviceByCode),
    deleteDeviceUseCaseProvider.overrideWithValue(deleteDevice),
    createDeviceUseCaseProvider.overrideWithValue(createDevice),
    setDeviceMuscleGroupsUseCaseProvider.overrideWithValue(setDeviceMuscles),
    updateDeviceMuscleGroupsUseCaseProvider.overrideWithValue(updateDeviceMuscles),
    exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
    getExercisesForDeviceProvider.overrideWithValue(getExercises),
    createExerciseUseCaseProvider.overrideWithValue(createExercise),
    deleteExerciseUseCaseProvider.overrideWithValue(deleteExercise),
    updateExerciseUseCaseProvider.overrideWithValue(updateExercise),
    updateExerciseMuscleGroupsUseCaseProvider.overrideWithValue(
      updateExerciseMuscles,
    ),
  ];
}

class _FakeReportRepository implements ReportRepository {
  @override
  Future<List<DateTime>> fetchAllLogTimestamps(String gymId,
          {DateTime? since}) async =>
      const [];

  @override
  Future<List<DeviceUsageStat>> fetchDeviceUsageStats(String gymId,
          {DateTime? since}) async =>
      const [];
}

class _FakeMembershipService implements MembershipService {
  final List<(String gymId, String uid)> calls = [];

  @override
  Future<void> ensureMembership(String gymId, String uid) async {
    calls.add((gymId, uid));
  }
}

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _error;
  String? _gymCode;
  String? _userId;
  String? _userName;
  List<String>? _gymCodes;
  GymContextStatus _status = GymContextStatus.unknown;
  GymScopedStateController? _gymScopedController;

  void attachGymScopedController(GymScopedStateController controller) {
    _gymScopedController = controller;
  }

  void setUserName(String? name) {
    _userName = name;
  }

  void updateState({
    bool? isLoading,
    bool? isLoggedIn,
    bool? isAdmin,
    String? error,
    String? gymCode,
    GymContextStatus? status,
    String? userId,
    List<String>? gymCodes,
  }) {
    _isLoading = isLoading ?? _isLoading;
    _isLoggedIn = isLoggedIn ?? _isLoggedIn;
    _isAdmin = isAdmin ?? _isAdmin;
    _error = error;
    _gymCode = gymCode;
    _status = status ?? _status;
    _userId = userId;
    if (gymCodes != null) {
      _gymCodes = List<String>.from(gymCodes);
    }
    notifyListeners();
  }

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isLoggedIn => _isLoggedIn;

  @override
  bool get isAdmin => _isAdmin;

  @override
  String? get error => _error;

  @override
  GymContextStatus get gymContextStatus => _status;

  @override
  String? get gymCode => _gymCode;

  @override
  String? get userId => _userId;

  @override
  List<String>? get gymCodes => _gymCodes;

  @override
  String? get userEmail => null;

  @override
  String? get userName => _userName;

  @override
  String get avatarKey => 'default';

  @override
  String? get role => _isAdmin ? 'admin' : 'member';

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<GymSwitchResult> switchGym(String code) async {
    _gymCode = code;
    _status = GymContextStatus.ready;
    _error = null;
    _gymScopedController?.resetGymScopedState();
    notifyListeners();
    return const GymSwitchResult.success();
  }

  @override
  Future<GymSwitchResult> selectGym(String code) => switchGym(code);

  @override
  Future<void> logout() async {
    _isLoggedIn = false;
    _gymCode = null;
    _userId = null;
    _status = GymContextStatus.unknown;
    _gymScopedController?.resetGymScopedState();
    notifyListeners();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBrandingProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier
    implements BrandingProvider {
  Branding? _branding;
  bool _isLoading = false;
  String? _error;
  String? _gymId;

  void emitBranding(String? gymId, Branding? branding) {
    _gymId = gymId;
    _branding = branding;
    notifyListeners();
  }

  @override
  Branding? get branding => _branding;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  String? get gymId => _gymId;

  @override
  Future<void> loadBranding(String gymId, String uid) async {
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    emitBranding(gymId, Branding(primaryColor: '#5500FF'));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void resetGymScopedState() {
    _branding = null;
    _gymId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGymProvider extends ChangeNotifier
    with GymScopedResettableChangeNotifier
    implements GymProvider {
  GymConfig? _gym;
  List<Device> _devices = const [];
  bool _isLoading = false;
  String? _error;
  String? _lastRequestedGymId;

  @override
  GymConfig? get gym => _gym;

  @override
  List<Device> get devices => _devices;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  String? get lastRequestedGymId => _lastRequestedGymId;

  @override
  String get currentGymId => _gym?.id ?? '';

  @override
  Future<void> loadGymData(String gymId) async {
    _isLoading = true;
    _lastRequestedGymId = gymId;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    _gym = GymConfig(id: gymId, code: gymId, name: 'Gym $gymId');
    _isLoading = false;
    notifyListeners();
  }

  @override
  void resetGymScopedState() {
    _gym = null;
    _devices = const [];
    _isLoading = false;
    _error = null;
    _lastRequestedGymId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemePreferenceProvider extends ChangeNotifier
    implements ThemePreferenceProvider {
  BrandThemeId? _override;
  bool _hasLoaded = true;
  String? _uid;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  BrandThemeId? get override => _override;

  @override
  bool get hasLoaded => _hasLoaded;

  @override
  void setUser(String? uid) {
    _uid = uid;
    _hasLoaded = true;
    notifyListeners();
  }

  @override
  Future<void> setTheme(BrandThemeId? theme) async {
    _override = theme;
    notifyListeners();
  }

  @override
  BrandThemeId? manualDefaultForGym(String? gymId) => BrandThemeId.mintTurquoise;

  @override
  List<BrandThemeId> availableForGym(String? gymId) => BrandThemeId.values;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkoutDayController extends ChangeNotifier
    with GymScopedResettableChangeNotifier
    implements WorkoutDayController {
  int resetCount = 0;
  AuthViewState? lastAuth;

  void attachAuth(AuthViewState state) {
    lastAuth = state;
    notifyListeners();
  }

  @override
  void resetGymScopedState() {
    resetCount += 1;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeGymScopedRegistration();
    super.dispose();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockXpProvider extends Mock with ChangeNotifier implements XpProvider {}

class _MockChallengeProvider extends Mock
    with ChangeNotifier
    implements ChallengeProvider {}

class _MockWorkoutSessionDurationService extends Mock
    with ChangeNotifier
    implements WorkoutSessionDurationService {}

class _MockTrainingPlanProvider extends Mock
    with ChangeNotifier
    implements TrainingPlanProvider {}

class _MockProfileProvider extends Mock
    with ChangeNotifier
    implements ProfileProvider {}

class _MockPowerliftingProvider extends Mock
    with ChangeNotifier
    implements PowerliftingProvider {}

class _MockCreatineProvider extends Mock
    with ChangeNotifier
    implements CreatineProvider {}

class _MockMuscleGroupProvider extends Mock
    with ChangeNotifier
    implements MuscleGroupProvider {}

class _MockExerciseProvider extends Mock
    with ChangeNotifier
    implements ExerciseProvider {}

class _MockAllExercisesProvider extends Mock
    with ChangeNotifier
    implements AllExercisesProvider {}

class _MockAvatarInventoryProvider extends Mock
    with ChangeNotifier
    implements AvatarInventoryProvider {}

class _MockRestStatsService extends Mock implements RestStatsService {}

class _MockStorySessionService extends Mock implements StorySessionService {}

class _MockExerciseXpReassignmentService extends Mock
    implements ExerciseXpReassignmentService {}

class _MockNfcService extends Mock implements NfcService {}

class _MockReadNfcCode extends Mock implements ReadNfcCode {}

class _MockWriteNfcTagUseCase extends Mock implements WriteNfcTagUseCase {}

class _MockDeviceRepository extends Mock implements DeviceRepository {}

class _MockGetDevicesForGym extends Mock implements GetDevicesForGym {}

class _MockGetDeviceByNfcCode extends Mock implements GetDeviceByNfcCode {}

class _MockDeleteDeviceUseCase extends Mock implements DeleteDeviceUseCase {}

class _MockCreateDeviceUseCase extends Mock implements CreateDeviceUseCase {}

class _MockSetDeviceMuscleGroupsUseCase extends Mock
    implements SetDeviceMuscleGroupsUseCase {}

class _MockUpdateDeviceMuscleGroupsUseCase extends Mock
    implements UpdateDeviceMuscleGroupsUseCase {}

class _MockExerciseRepository extends Mock implements ExerciseRepository {}

class _MockGetExercisesForDevice extends Mock implements GetExercisesForDevice {}

class _MockCreateExerciseUseCase extends Mock implements CreateExerciseUseCase {}

class _MockDeleteExerciseUseCase extends Mock implements DeleteExerciseUseCase {}

class _MockUpdateExerciseUseCase extends Mock implements UpdateExerciseUseCase {}

class _MockUpdateExerciseMuscleGroupsUseCase extends Mock
    implements UpdateExerciseMuscleGroupsUseCase {}
