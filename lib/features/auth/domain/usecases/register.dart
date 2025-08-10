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
  final fb_auth.FirebaseAuth _auth;
  RegisterUseCase([AuthRepository? repo, fb_auth.FirebaseAuth? auth])
      : _repo = repo ?? AuthRepositoryImpl(),
        _auth = auth ?? fb_auth.FirebaseAuth.instance;

  Future<UserData> execute(String email, String password, String gymId) async {
    // 1) Nutzerkonto anlegen und UserData in Firestore speichern
    final user = await _repo.register(email, password, gymId);

    // 2) ID-Token forcieren, damit Custom Claims aktualisiert werden
    final fb_auth.User? fbUser = _auth.currentUser;
    if (fbUser != null) {
      await fbUser.reload();
      await fbUser.getIdToken(true);
    }

    return user;
  }
}
