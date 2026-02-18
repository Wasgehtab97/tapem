import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/home/application/owner_workspace_provider.dart';
import 'package:tapem/features/home/presentation/screens/owner_screen.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _RouteObserver extends NavigatorObserver {
  final List<String?> pushedRouteNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

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

Future<void> _pumpOwnerScreen(
  WidgetTester tester, {
  required _FakeAuthProvider auth,
  OwnerWorkspaceSnapshot? snapshot,
  Object? dashboardError,
  List<NavigatorObserver> navigatorObservers = const [],
}) async {
  final resolvedSnapshot =
      snapshot ??
      OwnerWorkspaceSnapshot(
        memberCount: 0,
        deviceCount: 0,
        openFeedbackCount: 0,
        openSurveyCount: 0,
        activeChallengeCount: 0,
        generatedAt: DateTime(2026, 2, 16, 12, 0),
      );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        ownerWorkspaceSnapshotProvider.overrideWith((ref, gymId) async {
          if (dashboardError != null) {
            throw dashboardError;
          }
          return resolvedSnapshot;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        navigatorObservers: navigatorObservers,
        routes: {
          '/': (_) => const Scaffold(body: OwnerScreen()),
          AppRouter.report: (_) => const Scaffold(body: Text('report-page')),
          AppRouter.admin: (_) => const Scaffold(body: Text('admin-page')),
          AppRouter.selectGym: (_) =>
              const Scaffold(body: Text('select-gym-page')),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('OwnerScreen', () {
    testWidgets('shows no-access state when user cannot manage gyms', (
      tester,
    ) async {
      final auth = _FakeAuthProvider(
        canManageGym: false,
        gymCode: 'gym-test',
        userId: 'uid-test',
      );

      await _pumpOwnerScreen(tester, auth: auth);

      final context = tester.element(find.byType(OwnerScreen));
      final loc = AppLocalizations.of(context)!;

      expect(find.text(loc.commonNoAccess), findsOneWidget);
      expect(find.text(loc.ownerNoAccessSubtitle), findsOneWidget);
    });

    testWidgets('shows missing gym state and routes to gym selection', (
      tester,
    ) async {
      final auth = _FakeAuthProvider(
        canManageGym: true,
        gymCode: null,
        userId: 'uid-test',
      );

      final observer = _RouteObserver();
      await _pumpOwnerScreen(
        tester,
        auth: auth,
        navigatorObservers: <NavigatorObserver>[observer],
      );

      final context = tester.element(find.byType(OwnerScreen));
      final loc = AppLocalizations.of(context)!;

      expect(find.text(loc.ownerGymContextMissingTitle), findsOneWidget);
      expect(find.text(loc.ownerGymContextMissingSubtitle), findsOneWidget);

      await tester.tap(find.text(loc.selectGymTitle));
      await tester.pumpAndSettle();

      expect(find.text('select-gym-page'), findsOneWidget);
      expect(observer.pushedRouteNames.last, AppRouter.selectGym);
    });

    testWidgets('shows error state when dashboard loading fails', (
      tester,
    ) async {
      final auth = _FakeAuthProvider(
        canManageGym: true,
        gymCode: 'gym-test',
        userId: 'uid-test',
      );

      await _pumpOwnerScreen(
        tester,
        auth: auth,
        dashboardError: Exception('boom'),
      );

      final context = tester.element(find.byType(OwnerScreen));
      final loc = AppLocalizations.of(context)!;

      expect(find.text(loc.ownerDashboardLoadErrorTitle), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
      expect(find.text(loc.communityRetryButton), findsOneWidget);
    });
  });
}
