import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:tapem/features/auth/data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';
import '../repositories/auth_repository.dart';

/// Use-Case für die Neuregistrierung eines Nutzers.
/// Nach erfolgreicher Erstellung im Auth-System und
/// in Firestore wird das Firebase ID-Token erneuert,
/// damit Custom Claims (z.B. role) direkt verfügbar sind.
class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase([AuthRepository? repo]) : _repo = repo ?? AuthRepositoryImpl();

  Future<UserData> execute(
      String email,
      String password,
      String gymId,
  ) async {
    // 1) Nutzerkonto anlegen und UserData in Firestore speichern
    final user = await _repo.register(email, password, gymId);

    // 2) ID-Token forcieren, damit Custom Claims aktualisiert werden
    final fb_auth.User? fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      await fbUser.reload();
      await fbUser.getIdToken(true);
    }

    return user;
  }
}
