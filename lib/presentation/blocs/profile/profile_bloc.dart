// lib/presentation/blocs/profile/profile_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';

import 'package:tapem/domain/usecases/profile/get_current_user_id.dart'
    show GetCurrentUserIdProfileUseCase;
import 'package:tapem/domain/usecases/profile/fetch_user_profile.dart'
    show FetchUserProfileUseCase;
import 'package:tapem/domain/usecases/profile/fetch_training_dates.dart'
    show FetchProfileTrainingDatesUseCase;
// import the whole file so we pick up the use case class
import 'package:tapem/domain/usecases/profile/fetch_pending_request.dart';
import 'package:tapem/domain/usecases/profile/respond_request.dart'
    show RespondRequestUseCase;
import 'package:tapem/domain/usecases/profile/sign_out.dart'
    show SignOutUseCase;

import 'package:tapem/domain/models/user_data.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentUserIdProfileUseCase _getUserId;
  final FetchUserProfileUseCase _fetchUser;
  final FetchProfileTrainingDatesUseCase _fetchDates;
  final FetchPendingRequestUseCase _fetchPending;
  final RespondRequestUseCase _respond;
  final SignOutUseCase _signOut;

  ProfileBloc({
    required GetCurrentUserIdProfileUseCase getUserId,
    required FetchUserProfileUseCase fetchUser,
    required FetchProfileTrainingDatesUseCase fetchDates,
    required FetchPendingRequestUseCase fetchPending,
    required RespondRequestUseCase respond,
    required SignOutUseCase signOut,
  })  : _getUserId = getUserId,
        _fetchUser = fetchUser,
        _fetchDates = fetchDates,
        _fetchPending = fetchPending,
        _respond = respond,
        _signOut = signOut,
        super(ProfileInitial()) {
    on<ProfileLoadAll>(_onLoadAll);
    on<ProfileRespondRequest>(_onRespond);
    on<ProfileSignOut>(_onSignOut);
  }

  Future<void> _onLoadAll(
    ProfileLoadAll event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final userId = await _getUserId();
      if (userId == null) {
        emit(ProfileFailure('Kein Nutzer angemeldet'));
        return;
      }

      final userMap = await _fetchUser(userId);
      final user = UserData(
        id: userId,
        email: userMap['email'] as String,
        displayName: userMap['displayName'] as String,
        joinedAt: DateTime.parse(userMap['joinedAt'] as String),
        totalExperience: userMap['totalExperience'] as int,
        currentStreak: userMap['currentStreak'] as int,
      );

      final dates = await _fetchDates(userId);
      final pending = await _fetchPending(userId);

      emit(ProfileLoadSuccess(
        user: user,
        trainingDates: dates,
        pendingRequest: pending,
      ));
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _onRespond(
    ProfileRespondRequest event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await _respond(event.requestId, event.accept);
      emit(ProfileRequestResponded(event.accept));
      add(ProfileLoadAll());
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }

  Future<void> _onSignOut(
    ProfileSignOut event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await _signOut();
      emit(ProfileSignedOut());
    } catch (e) {
      emit(ProfileFailure(e.toString()));
    }
  }
}
