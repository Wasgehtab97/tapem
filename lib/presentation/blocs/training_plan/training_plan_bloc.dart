// lib/presentation/blocs/training_plan/training_plan_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'training_plan_event.dart';
import 'training_plan_state.dart';

import 'package:tapem/domain/models/training_plan_model.dart';
import 'package:tapem/domain/usecases/training_plan/create_plan.dart';
import 'package:tapem/domain/usecases/training_plan/delete_plan.dart';
import 'package:tapem/domain/usecases/training_plan/load_plan_by_id.dart';
import 'package:tapem/domain/usecases/training_plan/load_plans.dart';
import 'package:tapem/domain/usecases/training_plan/start_plan.dart';
import 'package:tapem/domain/usecases/training_plan/update_plan.dart';

class TrainingPlanBloc extends Bloc<TrainingPlanEvent, TrainingPlanState> {
  final LoadPlansUseCase _loadPlans;
  final CreatePlanUseCase _createPlan;
  final DeletePlanUseCase _deletePlan;
  final UpdatePlanUseCase _updatePlan;
  final StartPlanUseCase _startPlan;
  final LoadPlanByIdUseCase _loadById;

  TrainingPlanBloc({
    required LoadPlansUseCase loadPlans,
    required CreatePlanUseCase createPlan,
    required DeletePlanUseCase deletePlan,
    required UpdatePlanUseCase updatePlan,
    required StartPlanUseCase startPlan,
    required LoadPlanByIdUseCase loadById,
  })  : _loadPlans = loadPlans,
        _createPlan = createPlan,
        _deletePlan = deletePlan,
        _updatePlan = updatePlan,
        _startPlan = startPlan,
        _loadById = loadById,
        super(TrainingPlanInitial()) {
    on<TrainingPlanLoadAll>(_onLoadAll);
    on<TrainingPlanLoadById>(_onLoadById);
    on<TrainingPlanCreate>(_onCreate);
    on<TrainingPlanUpdate>(_onUpdate);
    on<TrainingPlanDelete>(_onDelete);
    on<TrainingPlanStart>(_onStart);
  }

  Future<void> _onLoadAll(
    TrainingPlanLoadAll event,
    Emitter<TrainingPlanState> emit,
  ) async {
    emit(TrainingPlanLoading());
    try {
      final plans = await _loadPlans.call(userId: event.userId);
      emit(TrainingPlanLoadSuccess(plans));
    } catch (e) {
      emit(TrainingPlanFailure(e.toString()));
    }
  }

  Future<void> _onLoadById(
    TrainingPlanLoadById event,
    Emitter<TrainingPlanState> emit,
  ) async {
    emit(TrainingPlanLoading());
    try {
      final plan = await _loadById.call(
        userId: event.userId,
        planId: event.planId,
      );
      emit(TrainingPlanSelected(plan));
    } catch (e) {
      emit(TrainingPlanFailure(e.toString()));
    }
  }

  Future<void> _onCreate(
    TrainingPlanCreate event,
    Emitter<TrainingPlanState> emit,
  ) async {
    emit(TrainingPlanLoading());
    try {
      final id = await _createPlan.call(
        userId: event.userId,
        name: event.name,
      );
      emit(TrainingPlanCreateSuccess(id));

      // direkt im Anschluss neu laden
      final plans = await _loadPlans.call(userId: event.userId);
      emit(TrainingPlanLoadSuccess(plans));
    } catch (e) {
      emit(TrainingPlanFailure(e.toString()));
    }
  }

  Future<void> _onUpdate(
    TrainingPlanUpdate event,
    Emitter<TrainingPlanState> emit,
  ) async {
    emit(TrainingPlanLoading());
    try {
      await _updatePlan.call(plan: event.plan);
      emit(const TrainingPlanUpdateSuccess());

      final plans = await _loadPlans.call(userId: event.userId);
      emit(TrainingPlanLoadSuccess(plans));
    } catch (e) {
      emit(TrainingPlanFailure(e.toString()));
    }
  }

  Future<void> _onDelete(
    TrainingPlanDelete event,
    Emitter<TrainingPlanState> emit,
  ) async {
    emit(TrainingPlanLoading());
    try {
      await _deletePlan.call(
        userId: event.userId,
        planId: event.planId,
      );
      emit(const TrainingPlanDeleteSuccess());

      final plans = await _loadPlans.call(userId: event.userId);
      emit(TrainingPlanLoadSuccess(plans));
    } catch (e) {
      emit(TrainingPlanFailure(e.toString()));
    }
  }

  Future<void> _onStart(
    TrainingPlanStart event,
    Emitter<TrainingPlanState> emit,
  ) async {
    emit(TrainingPlanLoading());
    try {
      await _startPlan.call(
        userId: event.userId,
        planId: event.planId,
      );
      emit(const TrainingPlanStartSuccess());

      final plans = await _loadPlans.call(userId: event.userId);
      emit(TrainingPlanLoadSuccess(plans));
    } catch (e) {
      emit(TrainingPlanFailure(e.toString()));
    }
  }
}
