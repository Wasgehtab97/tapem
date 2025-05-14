import 'package:firebase_auth/firebase_auth.dart';
import 'package:tapem/domain/repositories/auth_repository.dart';
import 'package:tapem/data/sources/auth/firestore_auth_source.dart';


/// Firestore-Implementierung von [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final FirestoreAuthSource _source;
  final FirebaseAuth _auth;
  AuthRepositoryImpl({
    FirestoreAuthSource? source,
    FirebaseAuth? auth,
  })  : _source = source ?? FirestoreAuthSource(),
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String gymId,
  }) async {
    await _source.register(
      email: email,
      password: password,
      displayName: displayName,
      gymId: gymId,
    );
  }

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _source.login(email: email, password: password);
  }

  @override
  bool get isLoggedIn => _auth.currentUser != null;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<String?> getSavedGymId() => _source.getSavedGymId();

  @override
  Future<void> signOut() async {
    await _source.signOut();
  }
}
