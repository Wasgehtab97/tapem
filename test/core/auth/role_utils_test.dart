import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/auth/role_utils.dart';

void main() {
  group('resolveUserAccessTier', () {
    test('resolves guest before any other flags', () {
      final tier = resolveUserAccessTier(
        isGuest: true,
        isAdmin: true,
        isGymOwner: true,
      );

      expect(tier, UserAccessTier.guest);
    });

    test('resolves gymowner before admin for mixed flags', () {
      final tier = resolveUserAccessTier(
        isGuest: false,
        isAdmin: true,
        isGymOwner: true,
      );

      expect(tier, UserAccessTier.gymOwner);
    });

    test('resolves admin', () {
      final tier = resolveUserAccessTier(
        isGuest: false,
        isAdmin: true,
        isGymOwner: false,
      );

      expect(tier, UserAccessTier.admin);
    });

    test('resolves member as fallback', () {
      final tier = resolveUserAccessTier(
        isGuest: false,
        isAdmin: false,
        isGymOwner: false,
      );

      expect(tier, UserAccessTier.member);
    });
  });

  group('canAccessRestrictedMemberRoutes', () {
    test('denies guest and member', () {
      expect(canAccessRestrictedMemberRoutes(UserAccessTier.guest), isFalse);
      expect(canAccessRestrictedMemberRoutes(UserAccessTier.member), isFalse);
    });

    test('allows admin and gymowner', () {
      expect(canAccessRestrictedMemberRoutes(UserAccessTier.admin), isTrue);
      expect(canAccessRestrictedMemberRoutes(UserAccessTier.gymOwner), isTrue);
    });
  });
}
