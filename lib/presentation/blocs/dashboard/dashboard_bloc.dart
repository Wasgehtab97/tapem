import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/models/dashboard_data.dart';
import 'package:tapem/domain/usecases/dashboard/load_device.dart';
import 'package:tapem/domain/usecases/dashboard/add_set.dart';
import 'package:tapem/domain/usecases/dashboard/finish_session.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final LoadDeviceUseCase _loadDevice;
  final AddSetUseCase _addSet;
  final FinishSessionUseCase _finishSession;

  DashboardBloc({
    required LoadDeviceUseCase loadDevice,
    required AddSetUseCase addSet,
    required FinishSessionUseCase finishSession,
  })  : _loadDevice = loadDevice,
        _addSet = addSet,
        _finishSession = finishSession,
        super(DashboardInitial()) {
    on<DashboardLoad>(_onLoad);
    on<DashboardAddSet>(_onAddSet);
    on<DashboardFinish>(_onFinish);
  }

  Future<void> _onLoad(
    DashboardLoad ev,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final DashboardData data = await _loadDevice(
        deviceId: ev.deviceId,
        secretCode: ev.secretCode,
      );
      emit(DashboardLoadSuccess(data, ev.secretCode));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }

  Future<void> _onAddSet(
    DashboardAddSet ev,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      await _addSet(
        deviceId: ev.deviceId,
        exercise: ev.exercise,
        sets: ev.sets,
        weight: ev.weight,
        reps: ev.reps,
      );
      // nach dem Hinzufügen neu laden
      add(DashboardLoad(
        deviceId: ev.deviceId,
        secretCode: ev.secretCode,
      ));
    } catch (e) {
      emit(DashboardFailure('Fehler beim Hinzufügen: $e'));
    }
  }

  Future<void> _onFinish(
    DashboardFinish ev,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      await _finishSession(
        deviceId: ev.deviceId,
        exercise: ev.exercise,
      );
      // nach dem Beenden neu laden
      add(DashboardLoad(
        deviceId: ev.deviceId,
        secretCode: ev.secretCode,
      ));
    } catch (e) {
      emit(DashboardFailure('Fehler beim Beenden: $e'));
    }
  }
}
