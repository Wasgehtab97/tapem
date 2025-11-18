// lib/core/app/tapem_app.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../app_router.dart';
import '../../bootstrap/legacy_provider_scope.dart';
import '../../bootstrap/navigation.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/theme_loader.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/numeric_keypad/overlay_numeric_keypad.dart';
import '../app/global_listener_host.dart';

class TapemApp extends StatelessWidget {
  const TapemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegacyProviderScope(
      child: TapemMaterialApp(),
    );
  }
}

class TapemMaterialApp extends StatelessWidget {
  const TapemMaterialApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeLoader>().theme;
    final locale = context.watch<AppProvider>().locale;
    final keypad = context.read<OverlayNumericKeypadController>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: dotenv.env['APP_NAME'] ?? 'Tap\'em',
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
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const SplashScreen()),
      builder: (context, child) {
        final app = GlobalListenerHost(child: child ?? const SizedBox.shrink());
        return OverlayNumericKeypadHost(
          controller: keypad,
          outsideTapMode: OutsideTapMode.closeAfterTap,
          theme: NumericKeypadTheme.fromContext(context),
          child: app,
        );
      },
    );
  }
}
