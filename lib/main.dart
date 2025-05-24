// ignore_for_file: avoid_print, use_super_parameters

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
import 'core/theme/theme_loader.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/gym_provider.dart';
import 'core/providers/device_provider.dart';
import 'core/providers/history_provider.dart';
import 'core/providers/profile_provider.dart';
import 'core/providers/exercise_provider.dart';

import 'features/nfc/data/nfc_service.dart';
import 'features/nfc/domain/usecases/read_nfc_code.dart';
import 'features/nfc/domain/usecases/write_nfc_tag.dart';
import 'features/nfc/widgets/global_nfc_listener.dart';

import 'features/device/data/sources/firestore_device_source.dart';
import 'features/device/data/repositories/device_repository_impl.dart';
import 'features/device/domain/repositories/device_repository.dart';
import 'features/device/domain/usecases/create_device_usecase.dart';
import 'features/device/domain/usecases/get_devices_for_gym.dart';
import 'features/device/domain/usecases/get_device_by_nfc_code.dart';

import 'features/device/data/sources/firestore_exercise_source.dart';
import 'features/device/data/repositories/exercise_repository_impl.dart';
import 'features/device/domain/repositories/exercise_repository.dart';
import 'features/device/domain/usecases/get_exercises_for_device.dart';
import 'features/device/domain/usecases/create_exercise_usecase.dart';
import 'features/device/domain/usecases/delete_exercise_usecase.dart';

import 'features/splash/presentation/screens/splash_screen.dart';

/// Damit wir aus dem GlobalNfcListener navigieren können
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env laden (dev, fallback ignorieren)
  await dotenv.load(fileName: '.env.dev').catchError((_) {});

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
        Provider<NfcService>(create: (_) => NfcService()),
        Provider<ReadNfcCode>(
          create: (ctx) => ReadNfcCode(ctx.read<NfcService>()),
        ),
        Provider<WriteNfcTagUseCase>(
          create: (_) => WriteNfcTagUseCase(),
        ),

        // —— Device ——————————————————————————————
        Provider<DeviceRepository>(
          create: (_) => DeviceRepositoryImpl(FirestoreDeviceSource()),
        ),
        Provider<CreateDeviceUseCase>(
          create: (ctx) => CreateDeviceUseCase(ctx.read<DeviceRepository>()),
        ),
        Provider<GetDevicesForGym>(
          create: (ctx) => GetDevicesForGym(ctx.read<DeviceRepository>()),
        ),
        Provider<GetDeviceByNfcCode>(
          create: (ctx) => GetDeviceByNfcCode(ctx.read<DeviceRepository>()),
        ),

        // —— Exercises ————————————————————————————
        Provider<ExerciseRepository>(
          create: (_) => ExerciseRepositoryImpl(FirestoreExerciseSource()),
        ),
        Provider<GetExercisesForDevice>(
          create: (ctx) => GetExercisesForDevice(ctx.read<ExerciseRepository>()),
        ),
        Provider<CreateExerciseUseCase>(
          create: (ctx) => CreateExerciseUseCase(ctx.read<ExerciseRepository>()),
        ),
        Provider<DeleteExerciseUseCase>(
          create: (ctx) => DeleteExerciseUseCase(ctx.read<ExerciseRepository>()),
        ),

        // —— App-State ————————————————————————————
        ChangeNotifierProvider(
          create: (_) => ThemeLoader()..loadDefault(),
        ),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (ctx) => ExerciseProvider(
            getEx: ctx.read<GetExercisesForDevice>(),
            createEx: ctx.read<CreateExerciseUseCase>(),
            deleteEx: ctx.read<DeleteExerciseUseCase>(),
          ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeLoader>().theme;
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
