// lib/presentation/widgets/history/history_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/models/exercise_entry.dart';
import 'package:tapem/domain/repositories/history_repository.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

/// Zeigt eine Liste vergangener Trainingseinträge für ein bestimmtes Gerät.
class HistoryList extends StatelessWidget {
  final String deviceId;
  final String? exerciseFilter;

  const HistoryList({
    Key? key,
    required this.deviceId,
    this.exerciseFilter,
  }) : super(key: key);

  Future<List<ExerciseEntry>> _loadEntries(HistoryRepository repo) async {
    final userId = await repo.getCurrentUserId();
    if (userId == null) return const [];
    return repo.fetchHistory(
      userId: userId,
      deviceId: deviceId,
      exercise: exerciseFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HistoryRepository>();

    return FutureBuilder<List<ExerciseEntry>>(
      future: _loadEntries(repo),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snap.hasError) {
          return Center(child: Text('Fehler: ${snap.error}'));
        }
        final entries = snap.data!;
        if (entries.isEmpty) {
          return const Center(child: Text('Keine Historie verfügbar.'));
        }
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = entries[i];
            return ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(e.exercise),
              subtitle: Text(
                '${e.sets} Sätze × ${e.weight.toStringAsFixed(1)} kg × ${e.reps} Wdh.',
              ),
            );
          },
        );
      },
    );
  }
}
