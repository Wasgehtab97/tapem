// lib/presentation/blocs/auth/auth_event.dart

/// Events für den AuthBloc.
abstract class AuthEvent {}

/// Prüft beim Starten der App, ob der Nutzer bereits eingeloggt ist.
class AuthCheckStatus extends AuthEvent {}

/// Fordert das Einloggen mit E-Mail und Passwort an.
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

/// Fordert die Registrierung eines neuen Nutzers an.
class RegisterRequested extends AuthEvent {
  final String displayName;
  final String email;
  final String password;
  final String gymId;
  RegisterRequested({
    required this.displayName,
    required this.email,
    required this.password,
    required this.gymId,
  });
}

/// Fordert das Ausloggen an.
class LogoutRequested extends AuthEvent {}
