import 'package:flutter_bloc/flutter_bloc.dart';
import 'training_details_event.dart';
import 'training_details_state.dart';
import 'package:tapem/domain/usecases/training_details/get_current_user_id.dart';
import 'package:tapem/domain/usecases/training_details/fetch_details.dart';
import 'package:tapem/domain/models/exercise_entry.dart';

class TrainingDetailsBloc
    extends Bloc<TrainingDetailsEvent, TrainingDetailsState> {
  final GetCurrentUserIdDetailsUseCase _getUserId;
  final FetchTrainingDetailsUseCase _fetchDetails;

  TrainingDetailsBloc({
    required GetCurrentUserIdDetailsUseCase getCurrentUserId,
    required FetchTrainingDetailsUseCase fetchDetails,
  })  : _getUserId = getCurrentUserId,
        _fetchDetails = fetchDetails,
        super(TrainingDetailsInitial()) {
    on<TrainingDetailsLoad>(_onLoad);
  }

  Future<void> _onLoad(
    TrainingDetailsLoad event,
    Emitter<TrainingDetailsState> emit,
  ) async {
    emit(TrainingDetailsLoading());
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('Nicht eingeloggt');

      final raw = await _fetchDetails(
        userId: userId,
        dateKey: event.dateKey,
      );

      final entries = raw
          .map((map) => ExerciseEntry.fromMap(
                map,
                id: map['id'] as String,
              ))
          .toList(growable: false);

      emit(TrainingDetailsLoadSuccess(entries));
    } catch (e) {
      emit(TrainingDetailsFailure(e.toString()));
    }
  }
}
