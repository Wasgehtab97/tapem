import 'package:tapem/core/auth/role_utils.dart';

enum HomeTabSlot {
  gym,
  profile,
  nutrition,
  workout,
  report,
  admin,
  rank,
  owner,
  deals,
  plan,
  coaching,
}

Set<HomeTabSlot> visibleHomeTabSlotsForAccessTier(UserAccessTier tier) {
  return switch (tier) {
    UserAccessTier.guest => const {HomeTabSlot.gym},
    UserAccessTier.member => const {
      HomeTabSlot.gym,
      HomeTabSlot.profile,
      HomeTabSlot.workout,
      HomeTabSlot.rank,
      HomeTabSlot.deals,
      HomeTabSlot.coaching,
    },
    UserAccessTier.admin => const {
      HomeTabSlot.gym,
      HomeTabSlot.profile,
      HomeTabSlot.workout,
      HomeTabSlot.owner,
      HomeTabSlot.rank,
      HomeTabSlot.deals,
      HomeTabSlot.coaching,
    },
    UserAccessTier.gymOwner => const {
      HomeTabSlot.gym,
      HomeTabSlot.profile,
      HomeTabSlot.workout,
      HomeTabSlot.owner,
      HomeTabSlot.rank,
      HomeTabSlot.deals,
      HomeTabSlot.coaching,
    },
  };
}
