import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/auth/role_utils.dart';

void main() {
  group('AppRouter.shouldRedirectRestrictedRoute', () {
    test('does not redirect when member limitation is disabled', () {
      final shouldRedirect = AppRouter.shouldRedirectRestrictedRoute(
        routeName: AppRouter.admin,
        accessTier: UserAccessTier.member,
        limitTabsForMembers: false,
      );

      expect(shouldRedirect, isFalse);
    });

    test('does not redirect non-restricted routes', () {
      final shouldRedirect = AppRouter.shouldRedirectRestrictedRoute(
        routeName: AppRouter.home,
        accessTier: UserAccessTier.member,
        limitTabsForMembers: true,
      );

      expect(shouldRedirect, isFalse);
    });

    test('redirects member from restricted owner/admin routes', () {
      expect(
        AppRouter.shouldRedirectRestrictedRoute(
          routeName: AppRouter.report,
          accessTier: UserAccessTier.member,
          limitTabsForMembers: true,
        ),
        isTrue,
      );
      expect(
        AppRouter.shouldRedirectRestrictedRoute(
          routeName: AppRouter.adminDevices,
          accessTier: UserAccessTier.member,
          limitTabsForMembers: true,
        ),
        isTrue,
      );
    });

    test('allows admin and gymowner on restricted routes', () {
      expect(
        AppRouter.shouldRedirectRestrictedRoute(
          routeName: AppRouter.admin,
          accessTier: UserAccessTier.admin,
          limitTabsForMembers: true,
        ),
        isFalse,
      );
      expect(
        AppRouter.shouldRedirectRestrictedRoute(
          routeName: AppRouter.report,
          accessTier: UserAccessTier.gymOwner,
          limitTabsForMembers: true,
        ),
        isFalse,
      );
    });
  });
}
