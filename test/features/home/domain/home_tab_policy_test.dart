import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/auth/role_utils.dart';
import 'package:tapem/features/home/domain/home_tab_policy.dart';

void main() {
  group('visibleHomeTabSlotsForAccessTier', () {
    test(
      'admin sees owner workspace instead of nutrition/plan/report/admin tabs',
      () {
        final slots = visibleHomeTabSlotsForAccessTier(UserAccessTier.admin);

        expect(slots.contains(HomeTabSlot.owner), isTrue);
        expect(slots.contains(HomeTabSlot.nutrition), isFalse);
        expect(slots.contains(HomeTabSlot.plan), isFalse);
        expect(slots.contains(HomeTabSlot.report), isFalse);
        expect(slots.contains(HomeTabSlot.admin), isFalse);
      },
    );

    test('gymOwner sees owner workspace and also rank/deals tabs', () {
      final slots = visibleHomeTabSlotsForAccessTier(UserAccessTier.gymOwner);

      expect(slots.contains(HomeTabSlot.owner), isTrue);
      expect(slots.contains(HomeTabSlot.rank), isTrue);
      expect(slots.contains(HomeTabSlot.deals), isTrue);
    });

    test('member still sees rank and deals', () {
      final slots = visibleHomeTabSlotsForAccessTier(UserAccessTier.member);

      expect(slots.contains(HomeTabSlot.rank), isTrue);
      expect(slots.contains(HomeTabSlot.deals), isTrue);
    });
  });
}
