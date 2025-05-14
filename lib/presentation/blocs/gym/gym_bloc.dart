import 'package:flutter_bloc/flutter_bloc.dart';
import 'gym_event.dart';
import 'gym_state.dart';
import 'package:tapem/domain/usecases/gym/fetch_devices.dart';

class GymBloc extends Bloc<GymFetchDevices, GymState> {
  final FetchGymDevicesUseCase _fetchUseCase;

  GymBloc({required FetchGymDevicesUseCase fetchUseCase})
      : _fetchUseCase = fetchUseCase,
        super(GymInitial()) {
    on<GymFetchDevices>(_onFetchDevices);
  }

  Future<void> _onFetchDevices(
    GymFetchDevices event,
    Emitter<GymState> emit,
  ) async {
    emit(GymLoading());
    try {
      final list = await _fetchUseCase(nameQuery: event.nameQuery);
      emit(GymLoadSuccess(list));
    } catch (e) {
      emit(GymFailure(e.toString()));
    }
  }
}
