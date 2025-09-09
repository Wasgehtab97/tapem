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
  String? get gymCode => 'g1';
  @override
  String? get userId => 'A1';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NonAdminAuth extends ChangeNotifier implements AuthProvider {
  @override
  bool get isAdmin => false;
  @override
  String? get gymCode => 'g1';
  @override
  String? get userId => 'U2';
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('shows inventory items', (tester) async {
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
          'source': 'admin/manual',
          'createdBy': 'A1',
          'gymId': 'g1'
        });

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
    expect(find.byType(CircleAvatar), findsWidgets);
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
  });
}
