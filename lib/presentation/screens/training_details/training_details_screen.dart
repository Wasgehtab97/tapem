import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/models/exercise_entry.dart';
import 'package:tapem/presentation/blocs/training_details/training_details_bloc.dart';
import 'package:tapem/presentation/blocs/training_details/training_details_event.dart';
import 'package:tapem/presentation/blocs/training_details/training_details_state.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

class TrainingDetailsScreen extends StatelessWidget {
  final String selectedDate;

  const TrainingDetailsScreen({Key? key, required this.selectedDate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TrainingDetailsBloc(
        getCurrentUserId: ctx.read(),
        fetchDetails: ctx.read(),
      )..add(TrainingDetailsLoad(selectedDate)),
      child: Scaffold(
        appBar: AppBar(title: Text('Details: $selectedDate')),
        body: BlocBuilder<TrainingDetailsBloc, TrainingDetailsState>(
          builder: (ctx, state) {
            if (state is TrainingDetailsLoading) {
              return const Center(child: LoadingIndicator());
            }
            if (state is TrainingDetailsLoadSuccess) {
              final entries = state.entries;
              if (entries.isEmpty) {
                return const Center(child: Text('Keine Daten für diesen Tag.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const Divider(),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final dateStr = e.trainingDate != null
                      ? '${e.trainingDate!.day.toString().padLeft(2, '0')}.'
                          '${e.trainingDate!.month.toString().padLeft(2, '0')}.'
                          '${e.trainingDate!.year}'
                      : '';
                  return ListTile(
                    title: Text('${e.exercise} – $dateStr'),
                    subtitle:
                        Text('Sätze: ${e.sets}, Gewicht: ${e.weight} kg, Wdh.: ${e.reps}'),
                  );
                },
              );
            }
            if (state is TrainingDetailsFailure) {
              return Center(child: Text('Fehler: ${state.message}'));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
