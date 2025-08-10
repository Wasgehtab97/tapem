/// Feature flag toggles for the app.
///
/// To enable the new session sets table locally, set [uiSetsTableV1] to true.
/// In production this value should be provided by a remote config service.
class FeatureFlags {
  FeatureFlags._();

  /// Flag for new session sets table on the device page.
  static const bool uiSetsTableV1 = false; // Toggle for testing.
}
