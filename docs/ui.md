# Session Sets Table

This page documents the experimental table-based input on the device page.

- **Feature flag**: `ui_sets_table_v1`
- **Enable locally**: set the flag in `lib/core/feature_flags.dart`.

## QA checklist

- Header displays `SET | PREVIOUS | KGS | REPS | ✓`.
- `Add Set +` inserts a new row.
- Previous values show the last session or `—` when none.
- Feature flag `ui_sets_table_v1` can be toggled at runtime via Remote Config.

Known limitations: controller and advanced interactions are simplified and will be expanded later.
