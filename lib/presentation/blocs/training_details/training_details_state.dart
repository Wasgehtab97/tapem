// lib/presentation/blocs/training_details/training_details_state.dart

import 'package:tapem/domain/models/exercise_entry.dart';

abstract class TrainingDetailsState {}

class TrainingDetailsInitial extends TrainingDetailsState {}

class TrainingDetailsLoading extends TrainingDetailsState {}

class TrainingDetailsLoadSuccess extends TrainingDetailsState {
  final List<ExerciseEntry> entries;
  TrainingDetailsLoadSuccess(this.entries);
}

class TrainingDetailsFailure extends TrainingDetailsState {
  final String message;
  TrainingDetailsFailure(this.message);
}
