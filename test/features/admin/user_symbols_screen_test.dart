import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/admin/presentation/screens/user_symbols_screen.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeAuth extends ChangeNotifier implements AuthProvider {
  @override
  bool get isAdmin => true;
  @override
  String? get gymCode => 'gym_01';
  @override
  String? get userId => 'A1';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NonAdminAuth extends ChangeNotifier implements AuthProvider {
  @override
  bool get isAdmin => false;
  @override
  String? get gymCode => 'gym_01';
  @override
  String? get userId => 'U2';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('shows inventory and add flow', (tester) async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('users').doc('u1').set({'username': 'Alice'});
    await fs
        .collection('users')
        .doc('u1')
        .collection('avatarInventory')
        .doc('default')
        .set({
          'key': 'global/default',
          'createdAt': Timestamp.now(),
          'source': 'admin/manual'
        });
    await fs
        .collection('users')
        .doc('u1')
        .collection('avatarInventory')
        .doc('default2')
        .set({
          'key': 'global/default2',
          'createdAt': Timestamp.now(),
          'source': 'admin/manual'
        });
    await fs.collection('gyms').doc('gym_01').collection('users').doc('u1').set({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _FakeAuth()),
          ChangeNotifierProvider(
            create: (_) => AvatarInventoryProvider(firestore: fs),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UserSymbolsScreen(uid: 'u1', firestore: fs),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNWidgets(2));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Global (0)'), findsOneWidget);
    expect(find.text('Alle globalen Symbole bereits zugewiesen.'),
        findsOneWidget);
    expect(find.text('gym_01 (1)'), findsOneWidget);
    await tester.tap(find.byType(CircleAvatar).last);
    await tester.pump();
    await tester.tap(find.textContaining('Hinzufügen')); // button
    await tester.pumpAndSettle();
    expect(find.byType(CircleAvatar), findsNWidgets(3));
  });

  testWidgets('denies access for non-admin', (tester) async {
    final fs = FakeFirebaseFirestore();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => _NonAdminAuth()),
          ChangeNotifierProvider(
            create: (_) => AvatarInventoryProvider(firestore: fs),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UserSymbolsScreen(uid: 'u1', firestore: fs),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Kein Zugriff'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
