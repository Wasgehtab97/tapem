import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/auth/role_utils.dart';
import 'package:tapem/features/home/domain/home_tab_policy.dart';

void main() {
  group('visibleHomeTabSlotsForAccessTier', () {
    test('guest sees only gym tab', () {
      final tabs = visibleHomeTabSlotsForAccessTier(UserAccessTier.guest);

      expect(tabs, equals({HomeTabSlot.gym}));
    });

    test('member keeps member surface tabs', () {
      final tabs = visibleHomeTabSlotsForAccessTier(UserAccessTier.member);

      expect(
        tabs,
        equals({
          HomeTabSlot.gym,
          HomeTabSlot.profile,
          HomeTabSlot.workout,
          HomeTabSlot.rank,
          HomeTabSlot.deals,
          HomeTabSlot.coaching,
        }),
      );
    });

    test(
      'gymowner gets owner tab and excludes nutrition/plan/admin/report',
      () {
        final tabs = visibleHomeTabSlotsForAccessTier(UserAccessTier.gymOwner);

        expect(
          tabs,
          equals({
            HomeTabSlot.gym,
            HomeTabSlot.profile,
            HomeTabSlot.workout,
            HomeTabSlot.rank,
            HomeTabSlot.owner,
            HomeTabSlot.deals,
            HomeTabSlot.coaching,
          }),
        );
        expect(tabs.contains(HomeTabSlot.nutrition), isFalse);
        expect(tabs.contains(HomeTabSlot.plan), isFalse);
        expect(tabs.contains(HomeTabSlot.admin), isFalse);
        expect(tabs.contains(HomeTabSlot.report), isFalse);
      },
    );

    test('admin keeps full admin tab surface without owner tab', () {
      final tabs = visibleHomeTabSlotsForAccessTier(UserAccessTier.admin);

      expect(
        tabs,
        equals({
          HomeTabSlot.gym,
          HomeTabSlot.profile,
          HomeTabSlot.nutrition,
          HomeTabSlot.workout,
          HomeTabSlot.report,
          HomeTabSlot.admin,
          HomeTabSlot.rank,
          HomeTabSlot.deals,
          HomeTabSlot.plan,
          HomeTabSlot.coaching,
        }),
      );
      expect(tabs.contains(HomeTabSlot.owner), isFalse);
    });
  });
}
