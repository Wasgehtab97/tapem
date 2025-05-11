// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/theme/theme_loader.dart';
import 'widgets/nfc_global_listener.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
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

  // 2) Firebase initialisieren
  await Firebase.initializeApp();

  // 3) Offline-Persistence aktivieren
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  // 4) App starten
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
          builder: (ctx, child) => NfcGlobalListener(child: child!),

          // Einstieg über Splash
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/auth':   (_) => const AuthScreen(),
            '/home':   (_) => const HomePage(),
            '/dashboard':     (_) => const DashboardScreen(),
            '/history':       (_) => const HistoryScreen(),
            '/profile':       (_) => const ProfileScreen(),
            '/reporting':     (_) => const ReportDashboardScreen(),
            '/admin':         (_) => const AdminDashboardScreen(),
            '/trainingsplan': (_) => const TrainingsplanScreen(),
            '/gym':           (_) => const GymScreen(),
            '/rank':          (_) => const RankScreen(),
            '/affiliate':     (_) => const AffiliateScreen(),
          },
          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      },
    );
  }
}
