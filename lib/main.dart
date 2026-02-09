// lib/main.dart

import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/core/utils/network_image_error_utils.dart';

import 'bootstrap/bootstrap.dart';
import 'core/app/tapem_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrapResult = await bootstrapApp();

  // Crashlytics nur in Nicht-Debug-Builds aktivieren, um Entwicklungs-Assertions zu vermeiden.
  if (!kDebugMode) {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Flutter-spezifische Fehler an Crashlytics senden
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (isBenignNetworkImageError(details.exception)) {
          FirebaseCrashlytics.instance.recordFlutterError(details);
          return;
        }
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };

      // Alle übrigen Fehler in einer Zone abfangen
      runZonedGuarded(
        () {
          runApp(
            ProviderScope(
              overrides: bootstrapResult.toOverrides(),
              child: const TapemApp(),
            ),
          );
        },
        (error, stack) {
          if (isBenignNetworkImageError(error)) {
            FirebaseCrashlytics.instance.recordError(
              error,
              stack,
              fatal: false,
            );
            return;
          }
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        },
      );
      return;
    } catch (_) {
      // Falls Crashlytics nicht initialisiert werden kann, weiter ohne Monitoring starten.
    }
  }

  // Debug-Build oder Crashlytics nicht verfügbar: normal starten.
  runApp(
    ProviderScope(
      overrides: bootstrapResult.toOverrides(),
      child: const TapemApp(),
    ),
  );
}
