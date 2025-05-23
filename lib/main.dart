// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'app_router.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/device_provider.dart';
import 'core/providers/gym_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/theme/theme_loader.dart';

import 'features/device/data/repositories/device_repository_impl.dart';
import 'features/device/data/sources/firestore_device_source.dart';
import 'features/device/domain/repositories/device_repository.dart';
import 'features/device/domain/usecases/create_device_usecase.dart';
import 'features/device/domain/usecases/get_devices_for_gym.dart';
import 'features/device/domain/usecases/get_device_by_nfc_code.dart';

import 'features/nfc/data/nfc_service.dart';
import 'features/nfc/domain/usecases/read_nfc_code.dart';
import 'features/nfc/domain/usecases/write_nfc_tag.dart';
import 'features/nfc/widgets/global_nfc_listener.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

/// Damit wir auch aus dem GlobalNfcListener navigieren können
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env laden (dev, fallback leer)
  try {
    await dotenv.load(fileName: '.env.dev');
  } catch (_) {}

  // Firebase initialisieren
  await Firebase.initializeApp();
  fb_auth.FirebaseAuth.instance
      .setSettings(appVerificationDisabledForTesting: true);

  // Intl-Daten laden
  await initializeDateFormatting();

  runApp(const AppEntry());
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // —— NFC ——————————————————————————————————
        Provider(create: (_) => NfcService()),
        Provider(create: (ctx) => ReadNfcCode(ctx.read<NfcService>())),
        Provider(create: (ctx) => WriteNfcTagUseCase()),
        // —— Device ——————————————————————————————
        Provider<DeviceRepository>(
          create: (_) => DeviceRepositoryImpl(FirestoreDeviceSource()),
        ),
        Provider(create: (ctx) => CreateDeviceUseCase(ctx.read<DeviceRepository>())),
        Provider(create: (ctx) => GetDevicesForGym(ctx.read<DeviceRepository>())),
        Provider(create: (ctx) => GetDeviceByNfcCode(ctx.read<DeviceRepository>())),
        // —— App-State ————————————————————————————
        ChangeNotifierProvider(create: (_) => ThemeLoader()..loadDefault()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme  = context.watch<ThemeLoader>().theme;
    final locale = context.watch<AppProvider>().locale;

    return GlobalNfcListener(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: dotenv.env['APP_NAME'] ?? 'Tap’em',
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
        onUnknownRoute: (_) => MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        ),
      ),
    );
  }
}
