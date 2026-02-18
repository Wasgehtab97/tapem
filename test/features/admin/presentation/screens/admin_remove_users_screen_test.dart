import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/admin/presentation/screens/admin_remove_users_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  _FakeAuthProvider({
    required bool canManageGym,
    required String? gymCode,
    required String? userId,
  }) : _canManageGym = canManageGym,
       _gymCode = gymCode,
       _userId = userId;

  final bool _canManageGym;
  final String? _gymCode;
  final String? _userId;

  @override
  bool get canManageGym => _canManageGym;

  @override
  String? get gymCode => _gymCode;

  @override
  String? get userId => _userId;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeAuthProvider auth,
  required FakeFirebaseFirestore firestore,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((ref) => auth)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AdminRemoveUsersScreen(firestore: firestore),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AdminRemoveUsersScreen', () {
    testWidgets('shows no-access state when user cannot manage gym', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final auth = _FakeAuthProvider(
        canManageGym: false,
        gymCode: 'gym-a',
        userId: 'owner-1',
      );

      await _pumpScreen(tester, auth: auth, firestore: firestore);
      final loc = AppLocalizations.of(
        tester.element(find.byType(AdminRemoveUsersScreen)),
      )!;

      expect(find.text(loc.adminNoAccess), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsNothing);
    });

    testWidgets('removes member from selected gym after confirmation', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final auth = _FakeAuthProvider(
        canManageGym: true,
        gymCode: 'gym-a',
        userId: 'owner-1',
      );

      await firestore.collection('users').doc('user-1').set({
        'username': 'Alice',
        'gymCodes': ['gym-a'],
        'activeGymId': 'gym-a',
        'createdAt': Timestamp.now(),
      });
      await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('users')
          .doc('user-1')
          .set({'role': 'member'});

      await _pumpScreen(tester, auth: auth, firestore: firestore);
      await tester.pump(const Duration(milliseconds: 350));
      final loc = AppLocalizations.of(
        tester.element(find.byType(AdminRemoveUsersScreen)),
      )!;

      expect(find.text('Alice'), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      expect(find.text(loc.adminDeleteUserTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, loc.commonDelete));
      await tester.pumpAndSettle();

      final userDoc = await firestore.collection('users').doc('user-1').get();
      final membership = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('users')
          .doc('user-1')
          .get();
      final audit = await firestore
          .collection('gyms')
          .doc('gym-a')
          .collection('adminAudit')
          .get();

      expect(userDoc.exists, isTrue);
      expect(userDoc.data()!['gymCodes'], isEmpty);
      expect(userDoc.data()!.containsKey('activeGymId'), isFalse);
      expect(membership.exists, isFalse);
      expect(audit.docs.length, 1);
      expect(find.textContaining(loc.adminDeleteUserSuccess('Alice', '')), findsOneWidget);
    });
  });
}
