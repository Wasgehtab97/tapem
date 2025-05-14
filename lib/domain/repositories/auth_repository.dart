// lib/domain/repositories/auth_repository.dart

/// Schnittstelle für Authentifizierung.
abstract class AuthRepository {
  /// Registriert einen neuen Nutzer.
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String gymId,
  });

  /// Meldet einen Nutzer an.
  Future<void> login({
    required String email,
    required String password,
  });

  /// Ob ein Nutzer aktuell eingeloggt ist.
  bool get isLoggedIn;

  /// Aktuelle Nutzer-ID oder null.
  String? get currentUserId;

  /// Liest die gespeicherte Gym-ID aus.
  Future<String?> getSavedGymId();

  /// Meldet den Nutzer ab.
  Future<void> signOut();
}
