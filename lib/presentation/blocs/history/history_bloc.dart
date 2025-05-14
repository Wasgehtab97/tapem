import 'package:flutter_bloc/flutter_bloc.dart';
import 'history_event.dart';
import 'history_state.dart';
import 'package:tapem/domain/usecases/history/get_current_user_id.dart';
import 'package:tapem/domain/usecases/history/fetch_history.dart';

class HistoryBloc extends Bloc<HistoryLoad, HistoryState> {
  final GetCurrentUserIdHistoryUseCase _getUserId;
  final FetchHistoryUseCase _fetchHistory;

  HistoryBloc({
    required GetCurrentUserIdHistoryUseCase getUserId,
    required FetchHistoryUseCase fetchHistory,
  })  : _getUserId = getUserId,
        _fetchHistory = fetchHistory,
        super(HistoryInitial()) {
    on<HistoryLoad>(_onLoad);
  }

  Future<void> _onLoad(
    HistoryLoad event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final userId = await _getUserId();
      if (userId == null) {
        emit(HistoryFailure('Kein Nutzer angemeldet'));
        return;
      }
      final entries = await _fetchHistory(
        userId: userId,
        deviceId: event.deviceId,
        exercise: event.exerciseFilter,
      );
      emit(HistoryLoadSuccess(entries));
    } catch (e) {
      emit(HistoryFailure(e.toString()));
    }
  }
}
