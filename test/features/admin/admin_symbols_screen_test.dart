import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/admin/presentation/screens/admin_symbols_screen.dart';
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

void main() {
  testWidgets('lists members and filters by search', (tester) async {
    final fs = FakeFirebaseFirestore();
    await fs.collection('users').doc('u1').set({
      'username': 'Alice',
      'usernameLower': 'alice',
      'avatarKey': 'global/default',
      'gymCodes': ['g1'],
    });
    await fs.collection('users').doc('u2').set({
      'username': 'Bob',
      'usernameLower': 'bob',
      'avatarKey': 'global/default',
      'gymCodes': ['g1'],
    });
    await fs.collection('users').doc('u3').set({
      'username': 'Alina',
      'avatarKey': 'global/default',
      'gymCodes': ['g1'],
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _FakeAuth(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminSymbolsScreen(firestore: fs),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alina'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'al');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Alina'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
  });
}
