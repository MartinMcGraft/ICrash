/// Institution-scoped role, except [platformSuperAdmin] which is granted
/// platform-wide via the separate `platformAdmins` collection rather than a
/// membership document.
enum Role { platformSuperAdmin, institutionAdmin, manager, user }

extension RoleCodec on Role {
  String get id => name;

  static Role fromId(String id) => Role.values.firstWhere(
        (role) => role.name == id,
        orElse: () => Role.user,
      );
}

enum MembershipStatus { active, invited, disabled }

extension MembershipStatusCodec on MembershipStatus {
  String get id => name;

  static MembershipStatus fromId(String id) => MembershipStatus.values.firstWhere(
        (status) => status.name == id,
        orElse: () => MembershipStatus.disabled,
      );
}
