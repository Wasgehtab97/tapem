# Muscle Group Widget Alignment

- Admin management page: `lib/features/muscle_group/presentation/screens/muscle_group_admin_screen.dart` shows muscle regions via `FilterChip` widgets.
- Names are provided through `MuscleGroupProvider` which reads from Firestore via `MuscleGroupRepositoryImpl`.
- Exercise add/edit flow previously used a `MuscleGroupSelectorList` with unlabeled checkboxes; names came from the same provider but visuals differed.
- New shared widgets:
  - `MuscleGroupLabelChip` renders a read-only chip for a single group.
  - `MuscleGroupSelector` provides multi-select chips with names and colors.
- Both widgets resolve ID → name/color through `MuscleGroupProvider` ensuring consistent i18n and theming with the admin implementation.
