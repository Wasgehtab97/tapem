import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tapem/domain/models/device_model.dart';
import 'package:tapem/domain/usecases/device/load_devices.dart';
import 'package:tapem/domain/usecases/device/register_device.dart';
import 'package:tapem/domain/usecases/device/update_device.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final LoadDevicesUseCase _loadAllUseCase;
  final RegisterDeviceUseCase _registerUseCase;
  final UpdateDeviceUseCase _updateUseCase;

  DeviceBloc({
    required LoadDevicesUseCase loadAll,
    required RegisterDeviceUseCase registerUseCase,
    required UpdateDeviceUseCase updateUseCase,
  })  : _loadAllUseCase = loadAll,
        _registerUseCase = registerUseCase,
        _updateUseCase = updateUseCase,
        super(DeviceInitial()) {
    on<DeviceLoadAll>(_onLoadAll);
    on<DeviceRegisterRequested>(_onRegister);
    on<DeviceUpdateRequested>(_onUpdate);
  }

  Future<void> _onLoadAll(
    DeviceLoadAll event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceLoading());
    try {
      final devices = await _loadAllUseCase();
      emit(DeviceLoaded(devices));
    } catch (e) {
      emit(DeviceFailure(e.toString()));
    }
  }

  Future<void> _onRegister(
    DeviceRegisterRequested event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceLoading());
    try {
      final newId = await _registerUseCase(
        name: event.name,
        exerciseMode: event.exerciseMode,
      );
      emit(DeviceRegisterSuccess(newId));
    } catch (e) {
      emit(DeviceFailure(e.toString()));
    }
  }

  Future<void> _onUpdate(
    DeviceUpdateRequested event,
    Emitter<DeviceState> emit,
  ) async {
    emit(DeviceLoading());
    try {
      await _updateUseCase(
        documentId: event.documentId,
        name: event.name,
        exerciseMode: event.exerciseMode,
        secretCode: event.secretCode,
      );
      emit(DeviceUpdateSuccess());
    } catch (e) {
      emit(DeviceFailure(e.toString()));
    }
  }
}
