import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/auth/role_utils.dart';

void main() {
  group('role helpers', () {
    test('supports member/gymowner/admin role helpers', () {
      expect(isMemberRole('member'), isTrue);
      expect(isGymOwnerRole('gymowner'), isTrue);
      expect(isAppAdminRole('admin'), isTrue);
      expect(isAdminLikeRole('member'), isFalse);
      expect(isAdminLikeRole('gymowner'), isTrue);
      expect(isAdminLikeRole('admin'), isTrue);
    });
  });

  group('resolveUserAccessTier', () {
    test('prioritizes guest', () {
      final tier = resolveUserAccessTier(
        isGuest: true,
        isAdmin: true,
        isGymOwner: true,
      );
      expect(tier, UserAccessTier.guest);
    });

    test('prioritizes admin over gymowner', () {
      final tier = resolveUserAccessTier(
        isGuest: false,
        isAdmin: true,
        isGymOwner: true,
      );
      expect(tier, UserAccessTier.admin);
    });

    test('returns gymowner for gymowner without admin', () {
      final tier = resolveUserAccessTier(
        isGuest: false,
        isAdmin: false,
        isGymOwner: true,
      );
      expect(tier, UserAccessTier.gymOwner);
    });

    test('defaults to member', () {
      final tier = resolveUserAccessTier(
        isGuest: false,
        isAdmin: false,
        isGymOwner: false,
      );
      expect(tier, UserAccessTier.member);
    });
  });
}
