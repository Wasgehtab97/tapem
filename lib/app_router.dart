// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:tapem/core/auth/role_utils.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_devices_screen.dart';
import 'package:tapem/features/manufacturer/presentation/screens/manage_manufacturers_screen.dart'; // NEW
import 'package:tapem/features/deals/presentation/screens/deals_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_deals_screen.dart';
import 'package:tapem/features/auth/presentation/screens/gym_access_screen.dart';
import 'package:tapem/features/auth/presentation/screens/gym_login_screen.dart';
import 'package:tapem/features/auth/presentation/screens/gym_register_method_screen.dart';
import 'package:tapem/features/auth/presentation/screens/gym_register_screen.dart';
import 'package:tapem/features/device/presentation/screens/workout_day_screen.dart';
import 'package:tapem/features/device/presentation/widgets/workout_day_table_card.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/features/history/presentation/screens/history_screen.dart';
import 'package:tapem/features/progress/presentation/screens/progress_screen.dart';
import 'package:tapem/features/home/presentation/screens/home_screen.dart';
import 'package:tapem/features/admin/presentation/screens/branding_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/features/gym/presentation/screens/select_gym_screen.dart';
import 'package:tapem/features/gym/presentation/screens/gym_entry_screen.dart';
import 'package:tapem/features/gym/presentation/screens/gym_add_membership_screen.dart';
import 'package:tapem/features/gym/presentation/screens/gym_join_screen.dart';
import 'package:tapem/features/gym/presentation/screens/gym_switch_screen.dart';
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
import 'package:tapem/features/creatine/presentation/screens/creatine_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_symbols_screen.dart';
import 'package:tapem/features/admin/presentation/screens/admin_remove_users_screen.dart';
import 'package:tapem/features/admin/presentation/screens/user_symbols_screen.dart';
import 'package:tapem/features/rest_stats/presentation/screens/rest_stats_screen.dart';
import 'package:tapem/features/community/presentation/screens/community_screen.dart';
import 'package:tapem/features/settings/presentation/screens/settings_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_day_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_home_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_calendar_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_goals_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_entry_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_scan_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_product_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_search_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_recipe_list_screen.dart';
import 'package:tapem/features/nutrition/presentation/screens/nutrition_recipe_edit_screen.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_product.dart';
import 'package:tapem/features/nutrition/domain/models/nutrition_recipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/config/feature_flags.dart';
import 'package:tapem/features/profile/presentation/screens/powerlifting_screen.dart';
import 'package:tapem/core/widgets/admin_access_guard.dart';
import 'package:tapem/core/widgets/gym_context_guard.dart';
import 'bootstrap/navigation.dart';
import 'bootstrap/providers.dart';
import 'package:tapem/features/training_plan/domain/models/training_plan.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_detail_screen.dart';
import 'package:tapem/features/training_plan/presentation/screens/plan_exercise_picker_screen.dart';

class AppRouter {
  static const splash = '/';
  static const auth = '/auth';
  static const gymEntry = '/gym_entry';
  static const gymAccess = '/gym_access';
  static const gymLogin = '/gym_login';
  static const gymRegisterMethod = '/gym_register_method';
  static const gymRegister = '/gym_register';
  static const gymJoin = '/gym_join';
  static const gymAddMembership = '/gym_add_membership';
  static const gymSwitch = '/gym_switch';
  static const home = '/home';
  static const homeInitialIndexByRole = -1;
  static const workoutDay = '/workout_day';
  static const device = '/device';
  static const exerciseList = '/exercise_list';
  static const history = '/history';
  static const progress = '/progress';
  static const report = '/report';
  static const admin = '/admin';
  static const adminDevices = '/admin_devices';
  static const adminRemoveUsers = '/admin_remove_users';
  static const deals = '/deals';
  static const rank = '/rank';
  // Deprecated alias for backward compatibility
  static const rankScreen = rank;
  static const trainingDetails = '/training_details';
  static const selectGym = '/select_gym';
  static const planOverview = '/plan_overview';
  static const trainingPlanDetail = '/training_plan_detail';
  static const trainingPlanPicker = '/training_plan_picker';
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
  static const creatine = '/creatine';
  static const restStats = '/rest_stats';
  static const community = '/community';
  static const settings = '/settings';
  static const nutrition = '/nutrition';
  static const nutritionHome = '/nutrition/home';
  static const nutritionDay = '/nutrition/day';
  static const nutritionGoals = '/nutrition/goals';
  static const nutritionCalendar = '/nutrition/calendar';
  static const nutritionEntry = '/nutrition/entry';
  static const nutritionScan = '/nutrition/scan';
  static const nutritionProduct = '/nutrition/product';
  static const nutritionSearch = '/nutrition/search';
  static const nutritionRecipes = '/nutrition/recipes';
  static const nutritionRecipeEdit = '/nutrition/recipes/edit';
  static const adminDeals = '/admin/deals';
  static const manageManufacturers = '/admin/manufacturers'; // NEW

  static const restrictedRoutesForMembers = {
    report,
    admin,
    deals,
    adminDevices,
    adminRemoveUsers,
    branding,
    manageChallenges,
    adminSymbols,
    userSymbols,
    adminDeals,
    manageManufacturers, // NEW
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final deepLink = _routeFromGymPath(settings);
    if (deepLink != null) {
      return deepLink;
    }
    final authState = _readAuthState();
    final accessTier = authState?.accessTier ?? UserAccessTier.guest;
    final isRestricted = shouldRedirectRestrictedRoute(
      routeName: settings.name,
      accessTier: accessTier,
      limitTabsForMembers: FF.limitTabsForMembers,
    );
    if (isRestricted) {
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    }

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const GymEntryScreen());

      case gymEntry:
        return MaterialPageRoute(builder: (_) => const GymEntryScreen());

      case gymAccess:
        final gymId = settings.arguments as String?;
        if (gymId == null || gymId.isEmpty) {
          return MaterialPageRoute(builder: (_) => const GymEntryScreen());
        }
        return MaterialPageRoute(builder: (_) => GymAccessScreen(gymId: gymId));

      case gymLogin:
        final gymId = settings.arguments as String?;
        if (gymId == null || gymId.isEmpty) {
          return MaterialPageRoute(builder: (_) => const GymEntryScreen());
        }
        return MaterialPageRoute(builder: (_) => GymLoginScreen(gymId: gymId));

      case gymRegisterMethod:
        final gymId = settings.arguments as String?;
        if (gymId == null || gymId.isEmpty) {
          return MaterialPageRoute(builder: (_) => const GymEntryScreen());
        }
        return MaterialPageRoute(
          builder: (_) => GymRegisterMethodScreen(gymId: gymId),
        );

      case gymRegister:
        final args = settings.arguments;
        if (args is! GymRegisterArgs) {
          return MaterialPageRoute(builder: (_) => const GymEntryScreen());
        }
        return MaterialPageRoute(builder: (_) => GymRegisterScreen(args: args));

      case gymJoin:
        final gymId = settings.arguments as String?;
        if (gymId == null || gymId.isEmpty) {
          return MaterialPageRoute(builder: (_) => const GymEntryScreen());
        }
        return MaterialPageRoute(builder: (_) => GymJoinScreen(gymId: gymId));

      case gymAddMembership:
        return MaterialPageRoute(
          builder: (_) => const GymAddMembershipScreen(),
        );

      case gymSwitch:
        return MaterialPageRoute(builder: (_) => const GymSwitchScreen());

      case home:
        final initialIndex = settings.arguments as int? ?? 0;
        debugPrint(
          '🔀 [Router] home initialIndex=$initialIndex (name=${settings.name})',
        );
        return MaterialPageRoute(
          builder: (_) =>
              GymContextGuard(child: HomeScreen(initialIndex: initialIndex)),
        );

      case device:
        return onGenerateRoute(
          RouteSettings(name: workoutDay, arguments: settings.arguments),
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
        final entryRequestedAtRaw = args['entryRequestedAtMs'];
        final entryRequestedAtMs = entryRequestedAtRaw is int
            ? entryRequestedAtRaw
            : int.tryParse(entryRequestedAtRaw?.toString() ?? '');

        debugPrint(
          '🔀 [Router] workoutDay args gymId=$gymId deviceId=$deviceId exerciseId=$exerciseId planId=$planId planName=$planName entryRequestedAtMs=$entryRequestedAtMs',
        );
        return MaterialPageRoute(
          settings: RouteSettings(name: workoutDay, arguments: rawArgs),
          builder: (_) => WorkoutDayScreen(
            gymId: gymId,
            deviceId: deviceId,
            exerciseId: exerciseId,
            planId: planId,
            planName: planName,
            entryRequestedAtMs: entryRequestedAtMs,
            sessionBuilder: buildWorkoutDayTableSessionCard,
          ),
        );

      case exerciseList:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => ExerciseListScreen(
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
            ownerUserId: args['userId'] as String?,
          ),
        );

      case progress:
        return MaterialPageRoute(builder: (_) => const ProgressScreen());

      case report:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(child: ReportScreen()),
        );

      case restStats:
        return MaterialPageRoute(builder: (_) => const RestStatsScreen());

      case nutrition:
        return MaterialPageRoute(builder: (_) => const NutritionHomeScreen());

      case nutritionHome:
        return MaterialPageRoute(builder: (_) => const NutritionHomeScreen());

      case nutritionDay:
        return MaterialPageRoute(builder: (_) => const NutritionDayScreen());

      case nutritionGoals:
        return MaterialPageRoute(builder: (_) => const NutritionGoalsScreen());

      case nutritionCalendar:
        return MaterialPageRoute(
          builder: (_) => const NutritionCalendarScreen(),
        );

      case nutritionEntry:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionEntryScreen(
            initialBarcode: args['barcode'] as String?,
            initialName: args['name'] as String?,
            initialMeal: args['meal'] as String? ?? 'breakfast',
            initialProduct: args['product'] as NutritionProduct?,
            initialQty: (args['qty'] as num?)?.toDouble(),
            entryIndex: args['index'] as int?,
            initialDate: args['date'] as DateTime?,
            initialRecipe: args['recipe'] as NutritionRecipe?,
          ),
        );

      case nutritionScan:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionScanScreen(
            initialMeal: args['meal'] as String? ?? 'breakfast',
            returnBarcode: args['returnBarcode'] as bool? ?? false,
          ),
        );

      case nutritionProduct:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionProductScreen(
            barcode: args['barcode'] as String? ?? '',
            initialMeal: args['meal'] as String? ?? 'breakfast',
          ),
        );

      case nutritionSearch:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) =>
              NutritionSearchScreen(initialQuery: args['query'] as String?),
        );
      case nutritionRecipes:
        final args = settings.arguments as Map<String, dynamic>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => NutritionRecipeListScreen(
            meal: args['meal'] as String?,
            isSelectionMode: args['isSelectionMode'] as bool? ?? false,
            date: args['date'] as DateTime?,
          ),
        );
      case nutritionRecipeEdit:
        final rawArgs = settings.arguments;
        NutritionRecipe? recipe;
        bool isLogMode = false;
        String? logMeal;
        DateTime? logDate;

        if (rawArgs is NutritionRecipe) {
          recipe = rawArgs;
        } else if (rawArgs is Map) {
          final val = rawArgs['recipe'];
          if (val is NutritionRecipe) {
            recipe = val;
          }
          isLogMode = rawArgs['isLogMode'] as bool? ?? false;
          logMeal = rawArgs['meal'] as String?;
          logDate = rawArgs['date'] as DateTime?;
        }
        return MaterialPageRoute(
          builder: (_) => NutritionRecipeEditScreen(
            recipe: recipe,
            isLogMode: isLogMode,
            logMeal: logMeal,
            logDate: logDate,
          ),
        );

      case community:
        return MaterialPageRoute(builder: (_) => const CommunityScreen());

      case AppRouter.settings:
        return SettingsScreen.route();

      case branding:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: BrandingScreen()),
          ),
        );

      case admin:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: AdminDashboardScreen()),
          ),
        );

      case adminDevices:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: AdminDevicesScreen()),
          ),
        );

      case adminRemoveUsers:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: AdminRemoveUsersScreen()),
          ),
        );

      case manageChallenges:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: ChallengeAdminScreen()),
          ),
        );

      case adminSymbols:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: AdminSymbolsScreen()),
          ),
        );

      case userSymbols:
        final uid = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(
            child: AdminAccessGuard(child: UserSymbolsScreen(uid: uid)),
          ),
        );

      case adminDeals:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: AdminDealsScreen()),
          ),
        );

      case manageManufacturers:
        return MaterialPageRoute(
          builder: (_) => const GymContextGuard(
            child: AdminAccessGuard(child: ManageManufacturersScreen()),
          ),
        );

      case deals:
        return MaterialPageRoute(builder: (_) => const DealsScreen());

      case rank:
        final args = settings.arguments as Map<String, String>? ?? const {};
        return MaterialPageRoute(
          builder: (_) => RankScreen(
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
          builder: (_) => const GymContextGuard(child: PlanOverviewScreen()),
        );

      case trainingPlanDetail:
        final plan = settings.arguments as TrainingPlan?;
        return MaterialPageRoute(
          builder: (_) => GymContextGuard(child: PlanDetailScreen(plan: plan)),
        );

      case trainingPlanPicker:
        return MaterialPageRoute(
          builder: (_) =>
              const GymContextGuard(child: PlanExercisePickerScreen()),
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
          builder: (_) => SurveyVoteScreen(
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
        return MaterialPageRoute(builder: (_) => const GymEntryScreen());
    }
  }

  static Route<dynamic>? _routeFromGymPath(RouteSettings settings) {
    final name = settings.name;
    if (name == null || !name.startsWith('/gym/')) {
      return null;
    }
    final parts = name.split('/')..removeWhere((segment) => segment.isEmpty);
    if (parts.length < 2) {
      return null;
    }
    final gymId = parts[1];
    if (gymId.isEmpty) {
      return null;
    }
    if (parts.length == 2) {
      return MaterialPageRoute(builder: (_) => GymAccessScreen(gymId: gymId));
    }
    final action = parts[2];
    switch (action) {
      case 'login':
        return MaterialPageRoute(builder: (_) => GymLoginScreen(gymId: gymId));
      case 'register':
        if (parts.length >= 4) {
          final method = parts[3];
          if (method == 'nfc') {
            return MaterialPageRoute(
              builder: (_) => GymRegisterScreen(
                args: GymRegisterArgs(
                  gymId: gymId,
                  method: GymRegisterMethod.nfc,
                ),
              ),
            );
          }
          if (method == 'code') {
            return MaterialPageRoute(
              builder: (_) => GymRegisterScreen(
                args: GymRegisterArgs(
                  gymId: gymId,
                  method: GymRegisterMethod.gymCode,
                ),
              ),
            );
          }
        }
        return MaterialPageRoute(
          builder: (_) => GymRegisterMethodScreen(gymId: gymId),
        );
      case 'join':
        return MaterialPageRoute(builder: (_) => GymJoinScreen(gymId: gymId));
      default:
        return MaterialPageRoute(builder: (_) => GymAccessScreen(gymId: gymId));
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

  @visibleForTesting
  static bool shouldRedirectRestrictedRoute({
    required String? routeName,
    required UserAccessTier accessTier,
    required bool limitTabsForMembers,
  }) {
    if (!limitTabsForMembers) {
      return false;
    }
    if (!restrictedRoutesForMembers.contains(routeName)) {
      return false;
    }
    return !canAccessRestrictedMemberRoutes(accessTier);
  }
}
