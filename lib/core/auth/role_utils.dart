const String kRoleAdmin = 'admin';
const String kRoleGymOwner = 'gymowner';

bool isAdminLikeRole(String? role) {
  return role == kRoleAdmin || role == kRoleGymOwner;
}

enum UserAccessTier { guest, member, admin, gymOwner }

UserAccessTier resolveUserAccessTier({
  required bool isGuest,
  required bool isAdmin,
  required bool isGymOwner,
}) {
  if (isGuest) {
    return UserAccessTier.guest;
  }
  if (isGymOwner) {
    return UserAccessTier.gymOwner;
  }
  if (isAdmin) {
    return UserAccessTier.admin;
  }
  return UserAccessTier.member;
}

bool canAccessRestrictedMemberRoutes(UserAccessTier tier) {
  return switch (tier) {
    UserAccessTier.admin || UserAccessTier.gymOwner => true,
    UserAccessTier.guest || UserAccessTier.member => false,
  };
}
