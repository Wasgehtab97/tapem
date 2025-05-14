// lib/presentation/widgets/dashboard/multi_exercise_selector.dart

import 'package:flutter/material.dart';

/// Auswahl mehrerer Übungsoptionen plus eigener Hinzufügungs-Button.
class MultiExerciseSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddCustom;

  const MultiExerciseSelector({
    Key? key,
    required this.options,
    this.selected,
    required this.onSelect,
    required this.onAddCustom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bitte wähle eine Übung',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          children: [
            for (var ex in options)
              ChoiceChip(
                label: Text(ex),
                selected: ex == selected,
                onSelected: (_) => onSelect(ex),
              ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Eigene Übung hinzufügen',
              onPressed: onAddCustom,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
