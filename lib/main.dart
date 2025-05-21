// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/core/providers/app_provider.dart'   as app;
import 'package:tapem/core/providers/auth_provider.dart'  as auth;
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.dev').catchError((_) {});
  await Firebase.initializeApp();
  fb_auth.FirebaseAuth.instance
      .setSettings(appVerificationDisabledForTesting: true);
  await initializeDateFormatting();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeLoader()..loadDefault()),
        ChangeNotifierProvider(create: (_) => app.AppProvider()),
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Theme und Locale aus unseren Providern holen
    final themeLoader = context.watch<ThemeLoader>();
    final appProv     = context.watch<app.AppProvider>();

    return MaterialApp(
      title: dotenv.env['APP_NAME'] ?? "Tap'em",
      debugShowCheckedModeBanner: false,
      theme: themeLoader.theme,              // unser Blau-Schwarz-Theme
      locale: appProv.locale,                // vom AppProvider gesteuert
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }
}
