// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_devices_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/features/auth/presentation/screens/auth_screen.dart';
import 'package:tapem/features/device/presentation/screens/workout_day_screen.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/features/history/presentation/screens/history_screen.dart';
import 'package:tapem/features/muscle_group/presentation/screens/muscle_group_admin_screen.dart';
import 'package:tapem/features/home/presentation/screens/home_screen.dart';
import 'package:tapem/features/admin/presentation/screens/branding_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/features/gym/presentation/screens/select_gym_screen.dart';
import 'package:tapem/features/training_details/presentation/screens/training_details_screen.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';
import 'package:tapem/features/rank/presentation/screens/powerlifting_leaderboard_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_overview_screen.dart';
import 'package:tapem/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tapem/features/xp/presentation/screens/xp_overview_screen.dart';
import 'package:tapem/features/challenges/presentation/screens/challenge_screen.dart';
import 'package:tapem/features/admin/presentation/screens/challenge_admin_screen.dart';
import 'package:tapem/features/xp/presentation/screens/day_xp_screen.dart';
import 'package:tapem/features/xp/presentation/screens/device_xp_screen.dart';
import 'package:tapem/features/feedback/presentation/screens/feedback_overview_screen.dart';
import 'package:tapem/features/survey/presentation/screens/survey_overview_screen.dart';
import 'package:tapem/features/survey/presentation/screens/survey_vote_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friends_home_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friend_detail_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friend_training_calendar_screen.dart';
import 'package:tapem/features/friends/presentation/screens/friend_chat_screen.dart';
import 'package:tapem/features/creatine/presentation/screens/creatine_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_symbols_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_remove_users_screen.dart';
import 'package:tapem/features/admin/presentation/screens/user_symbols_screen.dart';
import 'package:tapem/features/rest_stats/presentation/screens/rest_stats_screen.dart';
import 'package:tapem/features/community/presentation/screens/community_screen.dart';
import 'package:tapem/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/features/profile/presentation/screens/powerlifting_screen.dart';
import 'package:tapem/core/widgets/gym_context_guard.dart';
import 'bootstrap/navigation.dart';
import 'bootstrap/providers.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_detail_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_exercise_picker_screen.dart';

class AppRouter {
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const workoutDay = '/workout_day';
  static const device = '/device';
  static const exerciseList = '/exercise_list';
  static const history = '/history';
  static const report = '/report';
  static const admin = '/admin';
  static const adminDevices = '/admin_devices';
  static const adminRemoveUsers = '/admin_remove_users';
  static const affiliate = '/affiliate';
  static const rank = '/rank';
  // Deprecated alias for backward compatibility
  static const rankScreen = rank;
  static const trainingDetails = '/training_details';
  static const selectGym = '/select_gym';
  static const planOverview = '/plan_overview';
  static const trainingPlanDetail = '/training_plan_detail';
  static const trainingPlanPicker = '/training_plan_picker';
  static const manageMuscleGroups = '/manage_muscle_groups';
  static const branding = '/branding';
  static const resetPassword = '/reset_password';
  static const xpOverview = '/xp_overview';
  static const dayXp = '/day_xp';
  static const deviceXp = '/device_xp';
  static const challenges = '/challenges';
  static const manageChallenges = '/manage_challenges';
  static const adminSymbols = '/admin_symbols';
  static const userSymbols = '/user_symbols';
  static const powerlifting = '/powerlifting';
  static const powerliftingLeaderboard = '/powerlifting_leaderboard';
  static const feedbackOverview = '/feedback_overview';
  static const surveyOverview = '/survey_overview';
  static const surveyVote = '/survey_vote';
  static const friendsHome = '/friends';
  static const friendDetail = '/friend_detail';
  static const friendTrainingCalendar = '/friend_training_calendar';
  static const friendChat = '/friend_chat';
  static const creatine = '/creatine';
  static const restStats = '/rest_stats';
  static const community = '/community';
  static const settings = '/settings';

  static const restrictedRoutesForMembers = {
    report,
    admin,
    affiliate,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final authState = _readAuthState();
    final isRestricted = FF.limitTabsForMembers &&
        !(authState?.isAdmin ?? false) &&
        restrictedRoutesForMembers.contains(settings.name);
    if (isRestricted) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    }

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case home:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(
            child: HomeScreen(initialIndex: initialIndex),
          ),
        );

      case device:
        return onGenerateRoute(
          RouteSettings(
            name: workoutDay,
            arguments: settings.arguments,
          ),
        );

      case workoutDay:
        final rawArgs = settings.arguments;
        final args = rawArgs is Map
            ? Map<String, dynamic>.from(rawArgs as Map)
            : <String, dynamic>{};
        final gymId = args['gymId']?.toString() ?? '';
        final deviceId = args['deviceId']?.toString() ?? '';
        final exerciseId = args['exerciseId']?.toString() ?? '';
        final planId = args['planId']?.toString();
        final planName = args['planName']?.toString();

        debugPrint(
          '🔀 [Router] workoutDay args gymId=$gymId deviceId=$deviceId exerciseId=$exerciseId planId=$planId planName=$planName',
        );
        return MaterialPageRoute(
          settings: RouteSettings(
            name: workoutDay,
            arguments: rawArgs,
          ),
          builder: (_) => WorkoutDayScreen(
            gymId: gymId,
            deviceId: deviceId,
            exerciseId: exerciseId,
            planId: planId,
            planName: planName,
          ),
        );

      case exerciseList:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder:
              (_) => ExerciseListScreen(
                gymId: args['gymId']!,
                deviceId: args['deviceId']!,
              ),
        );

      case history:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(
            deviceId: args['deviceId'] as String,
            deviceName: args['deviceName'] as String,
            deviceDescription: args['deviceDescription'] as String?,
            isMulti: args['isMulti'] as bool? ?? false,
            exerciseId: args['exerciseId'] as String?,
            exerciseName: args['exerciseName'] as String?,
          ),
        );

      case report:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(child: ReportScreen()),
        );

      case restStats:
        return MaterialPageRoute(builder: (_) => const RestStatsScreen());

      case community:
        return MaterialPageRoute(builder: (_) => const CommunityScreen());

      case AppRouter.settings:
        return SettingsScreen.route();

      case manageMuscleGroups:
        return MaterialPageRoute(
          builder: (_) => const MuscleGroupAdminScreen(),
        );

      case branding:
        return MaterialPageRoute(builder: (_) => const BrandingScreen());

      case admin:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminDashboardScreen(),
          ),
        );

      case adminDevices:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminDevicesScreen(),
          ),
        );

      case adminRemoveUsers:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminRemoveUsersScreen(),
          ),
        );

      case manageChallenges:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: ChallengeAdminScreen(),
          ),
        );

      case adminSymbols:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminSymbolsScreen(),
          ),
        );

      case userSymbols:
        final uid = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(
            child: UserSymbolsScreen(uid: uid),
          ),
        );

      case affiliate:
        return MaterialPageRoute(builder: (_) => const AffiliateScreen());

      case rank:
        final args = settings.arguments as Map<String, String>? ?? const {};
        return MaterialPageRoute(
          builder:
              (_) => RankScreen(
                gymId: args['gymId'] ?? '',
                deviceId: args['deviceId'] ?? '',
              ),
        );

      case selectGym:
        return MaterialPageRoute(builder: (_) => const SelectGymScreen());

      case trainingDetails:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        final date = args['date'] as DateTime? ?? DateTime.now();
        final userId = args['userId'] as String? ?? '';
        final gymId = args['gymId'] as String?;
        return MaterialPageRoute(
          builder: (_) =>
              TrainingDetailsScreen(date: date, userId: userId, gymId: gymId),
        );

      case planOverview:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: PlanOverviewScreen(),
          ),
        );

      case trainingPlanDetail:
        final plan = settings.arguments as TrainingPlan?;
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(
            child: PlanDetailScreen(plan: plan),
          ),
        );

      case trainingPlanPicker:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: PlanExercisePickerScreen(),
          ),
        );

      case resetPassword:
        final code = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(oobCode: code),
        );

      case xpOverview:
        return MaterialPageRoute(builder: (_) => const XpOverviewScreen());

      case dayXp:
        return MaterialPageRoute(builder: (_) => const DayXpScreen());

      case deviceXp:
        return MaterialPageRoute(builder: (_) => const DeviceXpScreen());

      case challenges:
        return MaterialPageRoute(builder: (_) => const ChallengeScreen());

      case feedbackOverview:
        final gymId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => FeedbackOverviewScreen(gymId: gymId),
        );

      case surveyOverview:
        final gymId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => SurveyOverviewScreen(gymId: gymId),
        );

      case surveyVote:
        final args = settings.arguments as Map<String, String>? ?? const {};
        return MaterialPageRoute(
          builder:
              (_) => SurveyVoteScreen(
                gymId: args['gymId'] ?? '',
                userId: args['userId'] ?? '',
              ),
        );

      case friendsHome:
        return MaterialPageRoute(builder: (_) => const FriendsHomeScreen());

      case friendDetail:
        final uid = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => FriendDetailScreen(uid: uid));

      case friendTrainingCalendar:
        final args = settings.arguments as Map<String, String>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => FriendTrainingCalendarScreen(
            friendUid: args['uid'] ?? '',
            friendName: args['name'] ?? '',
          ),
        );

      case friendChat:
        final args = settings.arguments as Map<String, String>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => FriendChatScreen(
            friendUid: args['uid'] ?? '',
            friendName: args['name'] ?? '',
          ),
        );

      case creatine:
        return MaterialPageRoute(builder: (_) => const CreatineScreen());

      case powerlifting:
        return MaterialPageRoute(builder: (_) => const PowerliftingScreen());

      case powerliftingLeaderboard:
        return MaterialPageRoute(
          builder: (_) => const PowerliftingLeaderboardScreen(),
        );

      default:
        // Wenn Route nicht gefunden → zur Login-Maske redirecten
        // Das verhindert "Seite nicht gefunden" bei ungültigen/cached Routes
        return MaterialPageRoute(builder: (_) => const AuthScreen());
    }
  }

  static AuthViewState? _readAuthState() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return null;
    }
    try {
      final container = ProviderScope.containerOf(context);
      return container.read(authViewStateProvider);
    } catch (_) {
      return null;
    }
  }
}
