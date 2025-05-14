// lib/presentation/blocs/admin/admin_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_event.dart';
import 'admin_state.dart';
import 'package:tapem/domain/usecases/admin/fetch_devices.dart';
import 'package:tapem/domain/usecases/admin/create_device.dart';
import 'package:tapem/domain/usecases/admin/update_device.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final FetchDevicesUseCase _fetchDevices;
  final CreateDeviceUseCase _createDevice;
  final UpdateDeviceUseCase _updateDevice;

  AdminBloc({
    required FetchDevicesUseCase fetchDevices,
    required CreateDeviceUseCase createDevice,
    required UpdateDeviceUseCase updateDevice,
  })  : _fetchDevices = fetchDevices,
        _createDevice = createDevice,
        _updateDevice = updateDevice,
        super(AdminInitial()) {
    on<AdminFetchDevices>(_onFetchDevices);
    on<AdminCreateDevice>(_onCreateDevice);
    on<AdminUpdateDevice>(_onUpdateDevice);
  }

  Future<void> _onFetchDevices(
    AdminFetchDevices event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final list = await _fetchDevices();
      emit(AdminLoadSuccess(list));
    } catch (e) {
      emit(AdminFailure(e.toString()));
    }
  }

  Future<void> _onCreateDevice(
    AdminCreateDevice event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      final id = await _createDevice(
        name: event.name,
        exerciseMode: event.exerciseMode,
      );
      emit(AdminCreateSuccess(id));
      // Liste nach dem Erstellen neu laden
      final list = await _fetchDevices();
      emit(AdminLoadSuccess(list));
    } catch (e) {
      emit(AdminFailure(e.toString()));
    }
  }

  Future<void> _onUpdateDevice(
    AdminUpdateDevice event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    try {
      await _updateDevice(
        documentId: event.documentId,
        name: event.name,
        exerciseMode: event.exerciseMode,
        secretCode: event.secretCode,
      );
      emit(AdminUpdateSuccess()); // hier kein const
      // Liste nach dem Update neu laden
      final list = await _fetchDevices();
      emit(AdminLoadSuccess(list));
    } catch (e) {
      emit(AdminFailure(e.toString()));
    }
  }
}
