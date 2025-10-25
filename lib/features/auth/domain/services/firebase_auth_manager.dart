import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

/// Abstrakte Schnittstelle, um FirebaseAuth-Operationen zu kapseln
/// und dadurch in Tests mocken zu können.
abstract class FirebaseAuthManager {
  fb_auth.User? get currentUser;

  Future<void> reloadUser(fb_auth.User user);

  Future<void> forceRefreshIdToken(fb_auth.User user);

  Future<Map<String, dynamic>> getIdTokenClaims(fb_auth.User user);
}

class DefaultFirebaseAuthManager implements FirebaseAuthManager {
  final fb_auth.FirebaseAuth _firebaseAuth;

  DefaultFirebaseAuthManager({fb_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  @override
  fb_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> reloadUser(fb_auth.User user) => user.reload();

  @override
  Future<void> forceRefreshIdToken(fb_auth.User user) async {
    await user.getIdToken(true);
  }

  @override
  Future<Map<String, dynamic>> getIdTokenClaims(fb_auth.User user) async {
    final result = await user.getIdTokenResult();
    return result.claims ?? {};
  }
}
