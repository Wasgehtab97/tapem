// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/utils/logger.dart';
import 'core/tenant/tenant_service.dart';
import 'core/theme/theme_loader.dart';
import 'widgets/nfc_global_listener.dart';
import 'home_page.dart';
import 'screens/dashboard.dart';
import 'screens/history.dart';
import 'screens/profile.dart';
import 'screens/report_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/trainingsplan.dart';
import 'screens/gym.dart';
import 'screens/rank.dart';
import 'screens/affiliate_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Umgebungsvariablen laden (.env.dev oder .env.prod)
  await dotenv.load(fileName: kReleaseMode ? '.env.prod' : '.env.dev');
  AppLogger.log('Environment loaded: ${dotenv.env}');

  // 2) Firebase initialisieren
  await Firebase.initializeApp();
  AppLogger.log('Firebase initialized');

  // 3) Firestore Offline-Persistence aktivieren
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  AppLogger.log('Firestore offline persistence enabled');

  // 4) Initialen Tenant setzen (DEFAULT_GYM_ID aus .env, ansonsten 'defaultGym')
  final defaultGymId = dotenv.env['DEFAULT_GYM_ID'] ?? 'defaultGym';
  await TenantService().init(defaultGymId);
  AppLogger.log('Tenant initialized: $defaultGymId');

  // 5) App starten
  runApp(const TapemApp());
}

class TapemApp extends StatelessWidget {
  const TapemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeData>(
      future: ThemeLoader.loadTheme(),
      builder: (context, snapshot) {
        final theme = snapshot.data ?? ThemeData.light();
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: dotenv.env['APP_NAME'] ?? "Tap'em",
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: ThemeData.dark(),
          // NFC Listener global um alle Screens legen
          builder: (ctx, child) => NfcGlobalListener(child: child!),
          home: const HomePage(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/dashboard':
                return MaterialPageRoute(
                  builder: (_) => const DashboardScreen(),
                  settings: settings,
                );
              case '/history':
                return MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                  settings: settings,
                );
              case '/profile':
                return MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                  settings: settings,
                );
              case '/reporting':
                return MaterialPageRoute(
                  builder: (_) => const ReportDashboardScreen(),
                  settings: settings,
                );
              case '/admin':
                return MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen(),
                  settings: settings,
                );
              case '/trainingsplan':
                return MaterialPageRoute(
                  builder: (_) => const TrainingsplanScreen(),
                  settings: settings,
                );
              case '/gym':
                return MaterialPageRoute(
                  builder: (_) => const GymScreen(),
                  settings: settings,
                );
              case '/rank':
                return MaterialPageRoute(
                  builder: (_) => const RankScreen(),
                  settings: settings,
                );
              case '/affiliate':
                return MaterialPageRoute(
                  builder: (_) => const AffiliateScreen(),
                  settings: settings,
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const HomePage(),
                  settings: settings,
                );
            }
          },
          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      },
    );
  }
}
