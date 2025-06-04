import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../data/repositories/auth_repository_impl.dart';
import '../models/user_data.dart';
import '../repositories/auth_repository.dart';

/// Use-Case für die Anmeldung mit E-Mail und Passwort.
/// Nach erfolgreicher Authentifizierung wird das
/// Firebase ID-Token erneuert, damit Custom Claims
/// (z.B. role) sofort zur Verfügung stehen.
class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase([AuthRepository? repo]) : _repo = repo ?? AuthRepositoryImpl();

  Future<UserData> execute(String email, String password) async {
    // 1) Authentifizieren und UserData aus Firestore holen
    final user = await _repo.login(email, password);

    // 2) ID-Token forcieren, damit Custom Claims aktualisiert werden
    final fb_auth.User? fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      await fbUser.reload();
      await fbUser.getIdToken(true);
    }

    return user;
  }
}
