// lib/presentation/blocs/auth/auth_state.dart

/// States für den AuthBloc.
abstract class AuthState {}

/// Initialer Zustand (vor jeder Prüfung).
class AuthInitial extends AuthState {}

/// Lade-Zustand während Authvorgängen.
class AuthLoading extends AuthState {}

/// Zustand, wenn der Nutzer erfolgreich authentifiziert ist.
class Authenticated extends AuthState {}

/// Zustand, wenn kein Nutzer eingeloggt ist.
class Unauthenticated extends AuthState {}

/// Fehler-Zustand mit Fehlermeldung.
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
