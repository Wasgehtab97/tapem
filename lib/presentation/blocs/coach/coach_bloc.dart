// lib/presentation/blocs/coach/coach_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'coach_event.dart';
import 'coach_state.dart';

import 'package:tapem/domain/usecases/coach/load_clients.dart';
import 'package:tapem/domain/usecases/coach/fetch_training_dates.dart';
import 'package:tapem/domain/usecases/coach/send_request.dart'
    show SendCoachingRequestUseCase;
import 'package:tapem/domain/models/client_info.dart';

/// Bloc für das Coach-Feature.
class CoachBloc extends Bloc<CoachEvent, CoachState> {
  final LoadClientsUseCase _loadClients;
  final FetchTrainingDatesUseCase _fetchDates;
  final SendCoachingRequestUseCase _sendRequest;

  CoachBloc({
    required LoadClientsUseCase loadClients,
    required FetchTrainingDatesUseCase fetchDates,
    required SendCoachingRequestUseCase sendRequest,
  })  : _loadClients = loadClients,
        _fetchDates = fetchDates,
        _sendRequest = sendRequest,
        super(CoachInitial()) {
    on<CoachLoadClients>(_onLoadClients);
    on<CoachFetchTrainingDates>(_onFetchTrainingDates);
    on<CoachSendRequest>(_onSendRequest);
  }

  Future<void> _onLoadClients(
    CoachLoadClients event,
    Emitter<CoachState> emit,
  ) async {
    emit(CoachLoading());
    try {
      final List<ClientInfo> clients = await _loadClients.call(
        coachId: event.coachId,
      );
      emit(CoachClientsLoadSuccess(clients));
    } catch (e) {
      emit(CoachFailure(e.toString()));
    }
  }

  Future<void> _onFetchTrainingDates(
    CoachFetchTrainingDates event,
    Emitter<CoachState> emit,
  ) async {
    emit(CoachLoading());
    try {
      final List<String> dates = await _fetchDates.call(
        clientId: event.clientId,
      );
      emit(CoachDatesLoadSuccess(dates));
    } catch (e) {
      emit(CoachFailure(e.toString()));
    }
  }

  Future<void> _onSendRequest(
    CoachSendRequest event,
    Emitter<CoachState> emit,
  ) async {
    emit(CoachLoading());
    try {
      await _sendRequest.call(
        coachId: event.coachId,
        membershipNumber: event.membershipNumber,
      );
      emit(CoachRequestSuccess());
    } catch (e) {
      emit(CoachFailure(e.toString()));
    }
  }
}
