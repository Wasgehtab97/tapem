import 'package:flutter/foundation.dart';

class FF {
  // Standard auf false: „Letzte Session“-Card wird NICHT angezeigt.
  static const bool showLastSessionOnDevicePage = false;

  // TODO: Deaktivieren, wenn Mitglieder wieder alle Tabs sehen dürfen
  static const bool limitTabsForMembers = true;

  // Rollout-Flag fuer den neuen Owner-Hub.
  static bool get runtimeOwnerHubV1 {
    const v = String.fromEnvironment('OWNER_HUB_V1', defaultValue: 'true');
    return v.toLowerCase() == 'true';
  }

  // Zweite Ausbaustufe (Danger Zone + erweiterte Insights).
  static bool get runtimeOwnerHubV2 {
    const v = String.fromEnvironment('OWNER_HUB_V2', defaultValue: 'false');
    return v.toLowerCase() == 'true';
  }

  // Optional: für lokale Tests aktivierbar via dart-define
  // siehe: FF.runtimeShowLastSessionOnDevicePage
  static bool get runtimeShowLastSessionOnDevicePage {
    const v = String.fromEnvironment(
      'SHOW_LAST_SESSION_CARD',
      defaultValue: 'false',
    );
    return v.toLowerCase() == 'true';
  }

  @visibleForTesting
  static bool get isLastSessionVisible =>
      showLastSessionOnDevicePage || runtimeShowLastSessionOnDevicePage;
}
