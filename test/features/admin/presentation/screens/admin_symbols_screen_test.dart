import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/admin/data/services/gym_member_directory_service.dart';
import 'package:tapem/features/admin/presentation/screens/admin_symbols_screen.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  _FakeAuthProvider({
    required this.canManageGymValue,
    required this.gymCodeValue,
  });

  final bool canManageGymValue;
  final String? gymCodeValue;

  @override
  bool get canManageGym => canManageGymValue;

  @override
  String? get gymCode => gymCodeValue;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGymMemberDirectoryService extends GymMemberDirectoryService {
  _FakeGymMemberDirectoryService._(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);

  factory _FakeGymMemberDirectoryService() {
    final firestore = FakeFirebaseFirestore();
    return _FakeGymMemberDirectoryService._(firestore);
  }

  List<PublicProfile> profiles = const <PublicProfile>[];
  final List<String> backfillCalls = <String>[];

  @override
  Stream<List<PublicProfile>> watchProfilesForGym(String gymId) {
    return Stream<List<PublicProfile>>.value(profiles);
  }

  @override
  Future<int> backfillUsernameLower(
    String gymId, {
    Duration throttle = const Duration(milliseconds: 50),
  }) async {
    backfillCalls.add(gymId);
    return 3;
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeAuthProvider auth,
  required _FakeGymMemberDirectoryService service,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((ref) => auth)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: <String, WidgetBuilder>{
          '/': (_) => AdminSymbolsScreen(memberDirectoryService: service),
          AppRouter.userSymbols: (context) {
            final uid =
                ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return Scaffold(body: Text('user-symbols:$uid'));
          },
        },
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('AdminSymbolsScreen', () {
    testWidgets('shows no-access state for non-admin users', (tester) async {
      final auth = _FakeAuthProvider(
        canManageGymValue: false,
        gymCodeValue: 'gym-a',
      );
      final service = _FakeGymMemberDirectoryService();

      await _pumpScreen(tester, auth: auth, service: service);
      final loc = AppLocalizations.of(
        tester.element(find.byType(AdminSymbolsScreen)),
      )!;
      expect(find.text(loc.commonNoAccess), findsOneWidget);
    });

    testWidgets('filters profiles and navigates to user symbols', (
      tester,
    ) async {
      final auth = _FakeAuthProvider(
        canManageGymValue: true,
        gymCodeValue: 'gym-a',
      );
      final service = _FakeGymMemberDirectoryService()
        ..profiles = <PublicProfile>[
          const PublicProfile(
            uid: 'u1',
            username: 'Alice',
            usernameLower: 'alice',
          ),
          const PublicProfile(uid: 'u2', username: 'Bob', usernameLower: 'bob'),
        ];

      await _pumpScreen(tester, auth: auth, service: service);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ali');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsNothing);

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      expect(find.text('user-symbols:u1'), findsOneWidget);
    });
  });
}
