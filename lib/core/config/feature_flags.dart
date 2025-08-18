import 'package:flutter/foundation.dart';

class FF {
  // Standard auf false: „Letzte Session“-Card wird NICHT angezeigt.
  static const bool showLastSessionOnDevicePage = false;

  // Optional: für lokale Tests aktivierbar via dart-define
  // siehe: FF.runtimeShowLastSessionOnDevicePage
  static bool get runtimeShowLastSessionOnDevicePage {
    const v = String.fromEnvironment('SHOW_LAST_SESSION_CARD', defaultValue: 'false');
    return v.toLowerCase() == 'true';
  }

  @visibleForTesting
  static bool get isLastSessionVisible => showLastSessionOnDevicePage || runtimeShowLastSessionOnDevicePage;
}
