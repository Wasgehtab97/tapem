import 'package:flutter_bloc/flutter_bloc.dart';
import 'rank_event.dart';
import 'rank_state.dart';
import 'package:tapem/domain/usecases/rank/fetch_all_users.dart';

class RankBloc extends Bloc<RankEvent, RankState> {
  final FetchAllUsersUseCase _fetchAllUsers;

  RankBloc(this._fetchAllUsers) : super(RankInitial()) {
    on<RankLoadAll>(_onLoadAll);
  }

  Future<void> _onLoadAll(
    RankLoadAll event,
    Emitter<RankState> emit,
  ) async {
    emit(RankLoading());
    try {
      final users = await _fetchAllUsers();
      emit(RankLoadSuccess(users));
    } catch (e) {
      emit(RankFailure(e.toString()));
    }
  }
}
