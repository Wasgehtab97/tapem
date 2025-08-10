# Session Sets Table

This page documents the experimental table-based input on the device page.

- **Feature flag**: `ui_sets_table_v1`
- **Enable locally**: `flutter run --dart-define=UI_SETS_TABLE_V1=true`
- **Remote Config key**: `ui_sets_table_v1` (bool)

## QA checklist

- Header displays `SET | PREVIOUS | KGS | REPS | ✓`.
- `Add Set +` inserts a new row.
- Previous values show the last session or `—` when none.
- Feature flag `ui_sets_table_v1` can be toggled at runtime via Remote Config.

Expected behaviour: Hot reload or restart does not crash; toggling the flag in Remote Config switches the UI live once `fetchAndActivate` or a config update occurs.

Known limitations: controller and advanced interactions are simplified and will be expanded later.
