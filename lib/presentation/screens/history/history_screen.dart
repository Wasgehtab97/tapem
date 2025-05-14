// lib/presentation/screens/history/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tapem/presentation/blocs/history/history_bloc.dart';
import 'package:tapem/presentation/blocs/history/history_event.dart';
import 'package:tapem/presentation/blocs/history/history_state.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';
import 'package:tapem/domain/models/exercise_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final deviceId = args?['deviceId'] as String? ?? '';
      context
          .read<HistoryBloc>()
          .add(HistoryLoad(deviceId: deviceId, exerciseFilter: null));
      _didLoad = true;
    }
  }

  void _applyFilter(String exercise) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final deviceId = args?['deviceId'] as String? ?? '';
    context
        .read<HistoryBloc>()
        .add(HistoryLoad(deviceId: deviceId, exerciseFilter: exercise));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historie')),
      body: Column(
        children: [
          // Filter-Eingabe
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Übung filtern',
                suffixIcon: Icon(Icons.filter_alt),
                border: OutlineInputBorder(),
              ),
              onSubmitted: _applyFilter,
            ),
          ),
          // Einträge
          Expanded(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (ctx, state) {
                if (state is HistoryLoading) {
                  return const Center(child: LoadingIndicator());
                }
                if (state is HistoryLoadSuccess) {
                  final entries = state.entries;
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text('Keine Einträge gefunden.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      // Datum formatieren: DD.MM.YYYY
                      final date = e.trainingDate != null
                          ? '${e.trainingDate!.day.toString().padLeft(2, '0')}.'
                            '${e.trainingDate!.month.toString().padLeft(2, '0')}.'
                            '${e.trainingDate!.year}'
                          : '';
                      return ListTile(
                        title: Text('${e.exercise} – $date'),
                        subtitle: Text(
                          'Sätze: ${e.sets}, Gewicht: ${e.weight} kg, Wdh.: ${e.reps}',
                        ),
                      );
                    },
                  );
                }
                if (state is HistoryFailure) {
                  return Center(child: Text('Fehler: ${state.message}'));
                }
                // HistoryInitial
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
