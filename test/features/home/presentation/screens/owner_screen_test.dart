import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/home/presentation/screens/owner_screen.dart';

class _RouteObserver extends NavigatorObserver {
  final List<String?> pushedRouteNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

class _MockAuthProvider extends Mock
    with ChangeNotifier
    implements AuthProvider {}

void main() {
  group('OwnerScreen', () {
    testWidgets('navigates to report and admin via named routes', (
      tester,
    ) async {
      final auth = _MockAuthProvider();
      when(() => auth.gymCode).thenReturn('gym-test');
      when(() => auth.userId).thenReturn('uid-test');
      when(() => auth.role).thenReturn('gymowner');
      when(() => auth.isGymOwner).thenReturn(true);
      when(() => auth.refreshClaims()).thenAnswer((_) async {});

      final observer = _RouteObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith((ref) => auth)],
          child: MaterialApp(
            navigatorObservers: <NavigatorObserver>[observer],
            routes: {
              '/': (_) => const Scaffold(body: OwnerScreen()),
              AppRouter.report: (_) =>
                  const Scaffold(body: Text('report-page')),
              AppRouter.admin: (_) => const Scaffold(body: Text('admin-page')),
            },
          ),
        ),
      );

      await tester.tap(find.text('Report'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('report-page'), findsOneWidget);
      expect(observer.pushedRouteNames.last, AppRouter.report);

      Navigator.of(tester.element(find.text('report-page'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Admin'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('admin-page'), findsOneWidget);
      expect(observer.pushedRouteNames.last, AppRouter.admin);
    });
  });
}
