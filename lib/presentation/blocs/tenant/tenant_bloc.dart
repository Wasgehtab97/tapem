import 'package:flutter_bloc/flutter_bloc.dart';
import 'tenant_event.dart';
import 'tenant_state.dart';
import 'package:tapem/domain/usecases/tenant/get_saved_gym_id.dart' show GetSavedGymIdUseCase;
import 'package:tapem/domain/usecases/tenant/get_config.dart' show GetGymConfigUseCase;
import 'package:tapem/domain/usecases/tenant/switch_tenant.dart' show SwitchTenantUseCase;
import 'package:tapem/domain/models/tenant.dart';

/// Bloc für das Tenant-Feature.
class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final GetSavedGymIdUseCase _getId;
  final GetGymConfigUseCase _getCfg;
  final SwitchTenantUseCase _switch;

  TenantBloc({
    required GetSavedGymIdUseCase getSavedGymId,
    required GetGymConfigUseCase getGymConfig,
    required SwitchTenantUseCase switchTenant,
  })  : _getId = getSavedGymId,
        _getCfg = getGymConfig,
        _switch = switchTenant,
        super(TenantInitial()) {
    on<TenantLoad>(_onLoad);
    on<TenantInit>(_onInit);
  }

  Future<void> _onLoad(TenantLoad _, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      final id = await _getId();
      final cfg = _getCfg();
      if (id == null || cfg == null) throw Exception('Kein Gym ausgewählt');
      emit(TenantLoadSuccess(Tenant(gymId: id, config: cfg)));
    } catch (e) {
      emit(TenantFailure(e.toString()));
    }
  }

  Future<void> _onInit(TenantInit event, Emitter<TenantState> emit) async {
    emit(TenantLoading());
    try {
      await _switch(event.gymId);
      final id = await _getId();
      final cfg = _getCfg();
      if (id == null || cfg == null) throw Exception('Tenant-Ladevorgang fehlgeschlagen');
      emit(TenantLoadSuccess(Tenant(gymId: id, config: cfg)));
    } catch (e) {
      emit(TenantFailure(e.toString()));
    }
  }
}
