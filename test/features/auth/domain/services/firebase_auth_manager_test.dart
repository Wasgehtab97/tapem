import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/auth/domain/services/firebase_auth_manager.dart';

import '../../helpers/fakes.dart';

void main() {
  group('DefaultFirebaseAuthManager', () {
    late FakeFirebaseAuth firebaseAuth;
    late DefaultFirebaseAuthManager manager;
    late FakeFirebaseUser user;

    setUp(() {
      user = FakeFirebaseUser(uid: 'user-1', email: 'user@example.com', claims: {
        'role': 'admin',
      });
      firebaseAuth = FakeFirebaseAuth(currentUser: user);
      firebaseAuth.addUser(email: 'user@example.com', password: 'secret', user: user);
      manager = DefaultFirebaseAuthManager(firebaseAuth: firebaseAuth);
    });

    test('exposes the current user from FirebaseAuth', () {
      expect(manager.currentUser, same(user));
    });

    test('reloadUser delegates to Firebase user', () async {
      await manager.reloadUser(user);
      expect(user.reloadCount, 1);
    });

    test('forceRefreshIdToken requests a forced token refresh', () async {
      final before = user.tokenRequests;
      final claims = await manager.forceRefreshIdToken(user);
      expect(user.tokenRequests, greaterThan(before));
      expect(claims, containsPair('role', 'admin'));
    });

    test('getIdTokenClaims returns claims from IdTokenResult', () async {
      final claims = await manager.getIdTokenClaims(user);
      expect(claims, containsPair('role', 'admin'));
    });
  });
}
