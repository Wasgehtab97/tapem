import 'package:flutter/material.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/features/auth/presentation/screens/auth_screen.dart';
import 'package:tapem/features/device/presentation/screens/device_screen.dart';
import 'package:tapem/features/device/presentation/screens/exercise_list_screen.dart';
import 'package:tapem/features/history/presentation/screens/history_screen.dart';
import 'package:tapem/features/home/presentation/screens/home_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_dashboard_screen.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/features/training_details/presentation/screens/training_details_screen.dart';

class AppRouter {
  static const splash          = '/';
  static const auth            = '/auth';
  static const home            = '/home';
  static const device          = '/device';
  static const exerciseList    = '/exercise_list';
  static const history         = '/history';
  static const report          = '/report';
  static const admin           = '/admin';
  static const affiliate       = '/affiliate';
  static const trainingDetails = '/training_details';

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
          builder: (_) => DeviceScreen(
            gymId:      args['gymId']!,
            deviceId:   args['deviceId']!,
            exerciseId: args['exerciseId']!,
          ),
        );

      case exerciseList:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => ExerciseListScreen(
            gymId:    args['gymId']!,
            deviceId: args['deviceId']!,
          ),
        );

      case history:
        final deviceId = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(deviceId: deviceId),
        );

      case report:
        return MaterialPageRoute(builder: (_) => const ReportDashboardScreen());

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      case affiliate:
        return MaterialPageRoute(builder: (_) => const AffiliateScreen());

      case trainingDetails:
        final date = settings.arguments as DateTime? ?? DateTime.now();
        return MaterialPageRoute(
          builder: (_) => TrainingDetailsScreen(date: date),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Seite nicht gefunden')),
          ),
        );
    }
  }
}
