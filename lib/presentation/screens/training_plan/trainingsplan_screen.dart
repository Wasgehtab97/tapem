// lib/presentation/screens/training_plan/trainingsplan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:tapem/domain/models/exercise_entry.dart';
import 'package:tapem/domain/models/training_plan_model.dart';
import 'package:tapem/domain/repositories/auth_repository.dart';
import 'package:tapem/domain/repositories/training_plan_repository.dart';
import 'package:tapem/presentation/widgets/common/loading_indicator.dart';

class TrainingsplanScreen extends StatefulWidget {
  /// Die ID des anzuzeigenden/bearbeitenden Plans.
  final String planId;

  const TrainingsplanScreen({Key? key, required this.planId})
      : super(key: key);

  @override
  State<TrainingsplanScreen> createState() => _TrainingsplanScreenState();
}

class _TrainingsplanScreenState extends State<TrainingsplanScreen> {
  late final TrainingPlanRepository _repo;
  bool _isLoading = true;
  bool _isEditing = false;
  TrainingPlanModel? _plan;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _repo = context.read<TrainingPlanRepository>();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final userId = context.read<AuthRepository>().currentUserId;
    if (userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth');
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final plan = await _repo.loadPlanById(userId, widget.planId);
      setState(() => _plan = plan);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;
    setState(() => _isLoading = true);
    try {
      await _repo.updatePlan(_plan!);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Plan gespeichert')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addExercise() {
    if (_plan == null) return;
    setState(() {
      _plan!.exercises.add(
        ExerciseEntry(
          id: _uuid.v4(),
          exercise: 'Neue Übung',
          sets: 1,
          weight: 0.0,
          reps: 0,
          trainingDate: DateTime.now(),
        ),
      );
    });
  }

  void _removeExercise(int index) {
    setState(() => _plan!.exercises.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Plan bearbeiten'
            : 'Plan „${_plan?.name ?? ''}“'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              tooltip: _isEditing ? 'Speichern' : 'Bearbeiten',
              onPressed: () {
                if (_isEditing) {
                  _savePlan();
                } else {
                  setState(() => _isEditing = true);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _plan == null
              ? const Center(child: Text('Plan nicht gefunden.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _plan!.exercises.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final e = _plan!.exercises[i];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: _isEditing
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed:
                          _isEditing ? (_) => _removeExercise(i) : null,
                      child: ListTile(
                        title: Text(e.exercise),
                        subtitle: Text(_isEditing
                            ? 'Sätze: ${e.sets}, Gewicht: ${e.weight}, Wdh.: ${e.reps}'
                            : '${e.sets}× ${e.weight.toStringAsFixed(1)} kg, ${e.reps} Wdh.'),
                      ),
                    );
                  },
                ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _addExercise,
              tooltip: 'Übung hinzufügen',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
