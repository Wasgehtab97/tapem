import 'package:flutter/material.dart';
import 'package:tapem/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:tapem/features/affiliate/presentation/screens/affiliate_screen.dart';
import 'package:tapem/features/auth/presentation/screens/auth_screen.dart';
import 'package:tapem/features/device/presentation/screens/device_screen.dart';
import 'package:tapem/features/history/presentation/screens/history_screen.dart';
import 'package:tapem/features/home/presentation/screens/home_screen.dart';
import 'package:tapem/features/report/presentation/screens/report_dashboard_screen.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/features/training_details/presentation/screens/training_details_screen.dart';

class AppRouter {
  static const String splash          = '/';
  static const String auth            = '/auth';
  static const String home            = '/home';
  static const String device          = '/device';
  static const String history         = '/history';
  static const String report          = '/report';
  static const String admin           = '/admin';
  static const String affiliate       = '/affiliate';
  static const String trainingDetails = '/training_details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case home:
        final idx = settings.arguments as int? ?? 0;
        return MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: idx));
      case device:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => DeviceScreen(deviceId: id));
      case history:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(builder: (_) => HistoryScreen(deviceId: id));
      case report:
        return MaterialPageRoute(builder: (_) => const ReportDashboardScreen());
      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case affiliate:
        return MaterialPageRoute(builder: (_) => const AffiliateScreen());
      case trainingDetails:
        final date = settings.arguments as DateTime? ?? DateTime.now();
        return MaterialPageRoute(builder: (_) => TrainingDetailsScreen(date: date));
      default:
        return MaterialPageRoute(builder: (_) =>
          const Scaffold(body: Center(child: Text('Seite nicht gefunden'))));
    }
  }
}
