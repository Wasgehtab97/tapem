import 'package:flutter/material.dart';
import 'package:tapem/domain/models/exercise_entry.dart';

/// Zeigt eine Liste von [ExerciseEntry]s als Übersicht einer Trainingseinheit.
class SessionOverview extends StatelessWidget {
  final List<ExerciseEntry> entries;

  const SessionOverview({
    Key? key,
    required this.entries,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'Keine Übungen vorhanden.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final e = entries[index];
        return ListTile(
          leading: const Icon(Icons.fitness_center),
          title: Text(e.exercise), // nicht deviceName
          subtitle: Text('${e.sets} Sätze × ${e.reps} Wiederholungen'),
          trailing: Text('${e.weight.toStringAsFixed(1)} kg'),
        );
      },
    );
  }
}
