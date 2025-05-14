// lib/presentation/blocs/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:tapem/domain/usecases/auth/get_saved_gym_id.dart';
import 'package:tapem/domain/usecases/auth/login.dart';
import 'package:tapem/domain/usecases/auth/logout.dart';
import 'package:tapem/domain/usecases/auth/register.dart';

/// Bloc für Authentifizierung (Login/Logout/Registration).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetSavedGymIdUseCase _getSavedGymId;
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;

  AuthBloc({
    required GetSavedGymIdUseCase getSavedGymId,
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
  })  : _getSavedGymId = getSavedGymId,
        _login = login,
        _register = register,
        _logout = logout,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // prüfen, ob bereits eine Gym-ID gespeichert ist (impliziert eingeloggt)
      final gymId = await _getSavedGymId();
      if (gymId != null && gymId.isNotEmpty) {
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _login(email: event.email, password: event.password);
      emit(Authenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _register(
        displayName: event.displayName,
        email: event.email,
        password: event.password,
        gymId: event.gymId,
      );
      emit(Authenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
