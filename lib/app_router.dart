// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/features/auth/presentation/screens/auth_screen.dart';
import 'package:tapem/features/device/presentation/screens/device_screen.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/features/history/presentation/screens/history_screen.dart';
import 'package:tapem/features/muscle_group/presentation/screens/muscle_group_screen_new.dart';
import 'package:tapem/features/muscle_group/presentation/screens/muscle_group_admin_screen.dart';
import 'package:tapem/features/home/presentation/screens/home_screen.dart';
import 'package:tapem/features/admin/presentation/screens/branding_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_screen.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/features/gym/presentation/screens/select_gym_screen.dart';
import 'package:tapem/features/training_details/presentation/screens/training_details_screen.dart';
import 'package:tapem/features/rank/presentation/screens/rank_screen.dart';
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

class AppRouter {
  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const device = '/device';
  static const exerciseList = '/exercise_list';
  static const history = '/history';
  static const report = '/report';
  static const admin = '/admin';
  static const affiliate = '/affiliate';
  static const rank = '/rank';
  // Deprecated alias for backward compatibility
  static const rankScreen = rank;
  static const trainingDetails = '/training_details';
  static const selectGym = '/select_gym';
  static const planOverview = '/plan_overview';
  static const muscleGroups = '/muscle_groups';
  static const manageMuscleGroups = '/manage_muscle_groups';
  static const branding = '/branding';
  static const resetPassword = '/reset_password';
  static const xpOverview = '/xp_overview';
  static const dayXp = '/day_xp';
  static const deviceXp = '/device_xp';
  static const challenges = '/challenges';
  static const manageChallenges = '/manage_challenges';
  static const feedbackOverview = '/feedback_overview';
  static const surveyOverview = '/survey_overview';
  static const surveyVote = '/survey_vote';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case home:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(initialIndex: initialIndex),
        );

      case device:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder:
              (_) => DeviceScreen(
                gymId: args['gymId']!,
                deviceId: args['deviceId']!,
                exerciseId: args['exerciseId']!,
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
        final deviceId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(deviceId: deviceId),
        );

      case report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());

      case muscleGroups:
        return MaterialPageRoute(builder: (_) => const MuscleGroupScreenNew());

      case manageMuscleGroups:
        return MaterialPageRoute(
          builder: (_) => const MuscleGroupAdminScreen(),
        );

      case branding:
        return MaterialPageRoute(builder: (_) => const BrandingScreen());

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case manageChallenges:
        return MaterialPageRoute(builder: (_) => const ChallengeAdminScreen());

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
        final date = settings.arguments as DateTime? ?? DateTime.now();
        return MaterialPageRoute(
          builder: (_) => TrainingDetailsScreen(date: date),
        );

      case planOverview:
        return MaterialPageRoute(builder: (_) => const PlanOverviewScreen());

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

      default:
        return MaterialPageRoute(
          builder:
              (_) => const Scaffold(
                body: Center(child: Text('Seite nicht gefunden')),
              ),
        );
    }
  }
}
