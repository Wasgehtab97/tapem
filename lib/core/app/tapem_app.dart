// lib/core/app/tapem_app.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.dart';
import '../../bootstrap/legacy_provider_scope.dart';
import '../../bootstrap/navigation.dart';
import '../../core/providers/app_provider.dart';
import '../../core/theme/theme_loader.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/numeric_keypad/overlay_numeric_keypad.dart';
import '../app/global_listener_host.dart';

class _OverlayNavigatorObserver extends NavigatorObserver {
  final OverlayNumericKeypadController controller;
  _OverlayNavigatorObserver(this.controller);

  void _close() {
    controller.close();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _close();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _close();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _close();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _close();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class TapemApp extends StatelessWidget {
  const TapemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegacyProviderScope(
      child: TapemMaterialApp(),
    );
  }
}

class TapemMaterialApp extends ConsumerWidget {
  const TapemMaterialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeLoaderProvider).theme;
    final locale = ref.watch(appProvider).locale;
    final keypad = ref.watch(overlayNumericKeypadControllerProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [
        _OverlayNavigatorObserver(keypad),
      ],
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
          // Tastatur nur explizit schließen (z.B. über eigene Buttons),
          // damit Taps auf die Set-Felder nicht sofort wieder zum Schließen führen.
          outsideTapMode: OutsideTapMode.none,
          theme: NumericKeypadTheme.fromContext(context),
          child: app,
        );
      },
    );
  }
}
