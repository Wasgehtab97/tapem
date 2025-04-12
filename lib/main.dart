import 'package:flutter/material.dart';
import 'widgets/nfc_global_listener.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart'; // Gerätespezifische Trainingshistorie
import 'screens/profile.dart';
import 'screens/report_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/trainingsplan.dart';
import 'screens/gym.dart';
import 'screens/rank.dart';
import 'screens/affiliate_screen.dart';
import 'home_page.dart';
import 'theme/theme.dart'; // Zentrales Theme

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Gym Progress Tracking',
      debugShowCheckedModeBanner: false,
      theme: appTheme(), // Zentrales Theme wird hier angewendet
      builder: (context, child) => NfcGlobalListener(child: child!),
      home: const HomePage(),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/dashboard':
            return MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
              settings: settings,
            );
          case '/history':
            return MaterialPageRoute(
              builder: (context) => const HistoryScreen(),
              settings: settings,
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
              settings: settings,
            );
          case '/reporting':
            return MaterialPageRoute(
              builder: (context) => const ReportDashboardScreen(),
              settings: settings,
            );
          case '/admin':
            return MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
              settings: settings,
            );
          case '/trainingsplan':
            return MaterialPageRoute(
              builder: (context) => TrainingsplanScreen(),
              settings: settings,
            );
          case '/gym':
            return MaterialPageRoute(
              builder: (context) => GymScreen(),
              settings: settings,
            );
          case '/rank':
            return MaterialPageRoute(
              builder: (context) => const RankScreen(),
              settings: settings,
            );
          case '/affiliate':
            return MaterialPageRoute(
              builder: (context) => const AffiliateScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const HomePage(),
              settings: settings,
            );
        }
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const HomePage(),
        settings: settings,
      ),
    );
  }
}
