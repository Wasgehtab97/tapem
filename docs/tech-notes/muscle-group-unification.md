# Muscle Group Unification

This note summarises how muscle groups are resolved and rendered across the admin and exercise flows.

## Admin implementation
- **Screen**: `lib/features/muscle_group/presentation/screens/muscle_group_admin_screen.dart`
- **Widgets**: uses `FilterChip` for selection and `Chip` for display in `_showDeviceDialog` and device lists. Chips are labelled with `MuscleRegion` names and colour-coded via `Theme.colorScheme`.
- **Data source**: `MuscleGroupProvider` loads `MuscleGroup` objects from Firestore via `MuscleGroupRepositoryImpl`.

## Exercise flow
- **Bottom sheet**: `lib/features/device/presentation/widgets/exercise_bottom_sheet.dart` embeds `MuscleGroupSelector` for multi-select chips with labels and colours.
- **List tiles**: `MuscleChips` renders `MuscleGroupLabelChip` for each selected id, showing name + colour.

## Shared widgets
- `MuscleGroupLabelChip` resolves id → name/colour through `MuscleGroupProvider`.
- `MuscleGroupSelector` provides interactive multi-select chips with the same styling as admin.

Both flows now rely on the same provider and colour mapping (`muscle_group_color.dart`), ensuring consistent labels and colours.
