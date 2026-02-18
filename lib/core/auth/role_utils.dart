const String kRoleMember = 'member';
const String kRoleAdmin = 'admin';
const String kRoleGymOwner = 'gymowner';

bool isMemberRole(String? role) {
  return role == kRoleMember;
}

bool isAppAdminRole(String? role) {
  return role == kRoleAdmin;
}

bool isGymOwnerRole(String? role) {
  return role == kRoleGymOwner;
}

/// Roles with gym management privileges.
bool isAdminLikeRole(String? role) {
  return isAppAdminRole(role) || isGymOwnerRole(role);
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
  if (isAdmin) {
    return UserAccessTier.admin;
  }
  if (isGymOwner) {
    return UserAccessTier.gymOwner;
  }
  return UserAccessTier.member;
}

bool canAccessRestrictedMemberRoutes(UserAccessTier tier) {
  return switch (tier) {
    UserAccessTier.admin || UserAccessTier.gymOwner => true,
    UserAccessTier.guest || UserAccessTier.member => false,
  };
}
