// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:tapem/core/theme/theme_loader.dart';
import 'package:tapem/core/providers/app_provider.dart' as app;
import 'package:tapem/core/providers/auth_provider.dart' as auth;
import 'package:tapem/core/providers/gym_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/providers/history_provider.dart';
import 'package:tapem/core/providers/profile_provider.dart';

import 'package:tapem/features/nfc/data/nfc_service.dart';
import 'package:tapem/features/nfc/domain/usecases/read_nfc_code.dart';
import 'package:tapem/features/device/data/sources/firestore_device_source.dart';
import 'package:tapem/features/device/data/repositories/device_repository_impl.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/features/splash/presentation/screens/splash_screen.dart';
import 'package:tapem/features/nfc/widgets/global_nfc_listener.dart';

/// Globale navigatorKey, damit du aus jedem Kontext navigieren kannst.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        // NFC-Service + UseCase
        Provider<NfcService>(create: (_) => NfcService()),
        Provider<ReadNfcCode>(
          create: (ctx) => ReadNfcCode(ctx.read<NfcService>()),
        ),

        // Device-Repository
        Provider<DeviceRepository>(
          create: (_) => DeviceRepositoryImpl(FirestoreDeviceSource()),
        ),

        // App-State
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeLoader = context.watch<ThemeLoader>();
    final appProv = context.watch<app.AppProvider>();

    return GlobalNfcListener(
      child: MaterialApp(
        navigatorKey: navigatorKey, // ← hier setzen
        title: dotenv.env['APP_NAME'] ?? "Tap'em",
        debugShowCheckedModeBanner: false,
        theme: themeLoader.theme,
        locale: appProv.locale,
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
      ),
    );
  }
}
