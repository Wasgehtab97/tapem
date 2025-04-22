import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'widgets/nfc_global_listener.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart';
import 'screens/profile.dart';
import 'screens/report_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/trainingsplan.dart';
import 'screens/gym.dart';
import 'screens/rank.dart';
import 'screens/affiliate_screen.dart';
import 'home_page.dart';
import 'theme/theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Gym Progress',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      builder: (ctx, child) => NfcGlobalListener(child: child!),
      home: const HomePage(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen(), settings: settings);
          case '/history':
            return MaterialPageRoute(builder: (_) => const HistoryScreen(), settings: settings);
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen(), settings: settings);
          case '/reporting':
            return MaterialPageRoute(builder: (_) => const ReportDashboardScreen(), settings: settings);
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen(), settings: settings);
          case '/trainingsplan':
            return MaterialPageRoute(builder: (_) => const TrainingsplanScreen(), settings: settings);
          case '/gym':
            return MaterialPageRoute(builder: (_) => const GymScreen(), settings: settings);
          case '/rank':
            return MaterialPageRoute(builder: (_) => const RankScreen(), settings: settings);
          case '/affiliate':
            return MaterialPageRoute(builder: (_) => const AffiliateScreen(), settings: settings);
          default:
            return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
        }
      },
      onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }
}
