import 'package:flutter/material.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'muscle_chips.dart';

class ExerciseHeader extends StatelessWidget {
  final String name;
  final List<String> muscleGroupIds;
  final VoidCallback onChange;
  final VoidCallback? onEdit;

  const ExerciseHeader({
    super.key,
    required this.name,
    required this.muscleGroupIds,
    required this.onChange,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  MuscleChips(muscleGroupIds: muscleGroupIds),
                ],
              ),
            ),
            Column(
              children: [
                TextButton(
                  onPressed: onChange,
                  child: Text(loc.multiDevice_changeExercise),
                ),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    child: Text(loc.multiDevice_editExerciseButton),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
